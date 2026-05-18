import AppKit
import ServiceManagement
import Foundation
import Sub2APIStatusCore

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published var config: AppConfig
    @Published var snapshot: MonitorSnapshot
    @Published var isRefreshing = false
    @Published var isLoggingIn = false
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var settingsDraft: AppConfig
    @Published var settingsError: String?
    @Published var updateInfo: UpdateInfo?
    @Published var isCheckingForUpdates = false
    @Published var updateStatusMessage: String?
    @Published var launchAtLoginEnabled = false
    @Published var launchAtLoginError: String?
    @Published var focusesManualToken = false

    var onSnapshotChange: ((MonitorSnapshot) -> Void)?

    private let store = ConfigStore()
    private let updateChecker = GitHubUpdateChecker()
    private let insightNotifier = InsightNotifier()
    private var refreshTimer: Timer?

    init() {
        let loaded = store.load()
        config = loaded
        settingsDraft = loaded
        loginEmail = loaded.selectedAccount?.email ?? ""
        snapshot = .idle(mode: loaded.monitorMode)
        launchAtLoginEnabled = Self.currentLaunchAtLoginState()
    }

    func start() {
        refresh()
        scheduleTimer()
        checkForUpdates(silent: true)
    }

    func refresh() {
        Task {
            await refreshNow()
        }
    }

    func refreshNow() async {
        guard !isRefreshing else {
            return
        }

        if config.authToken.isEmpty {
            publish(.idle(mode: config.monitorMode))
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        let client = Sub2APIClient(config: config)
        do {
            publish(try await userSnapshot(client: client))
        } catch {
            if await refreshAuthTokenIfNeeded(after: error) {
                do {
                    publish(try await userSnapshot(client: Sub2APIClient(config: config)))
                    return
                } catch {
                    publishDisconnected(error)
                    return
                }
            }
            publishDisconnected(error)
        }
    }

    private func userSnapshot(client: Sub2APIClient) async throws -> MonitorSnapshot {
        let currentUser = try? await client.currentUser().user
        async let summaryTask = client.subscriptionSummary()
        async let statsTask = client.usageDashboardStats()
        let range = Self.lastSevenDayRange()
        async let trendTask = client.usageDashboardTrend(startDate: range.start, endDate: range.end, granularity: "day")
        async let modelsTask = client.usageDashboardModels(startDate: range.start, endDate: range.end)

        let summary = try await summaryTask
        let stats = try? await statsTask
        let trend = try? await trendTask
        let models = try? await modelsTask
        return MonitorSnapshot(
            mode: .user,
            connected: true,
            currentUser: currentUser,
            stats: stats,
            trend: trend?.trend,
            modelDistribution: models?.models,
            realtime: nil,
            accountHealth: nil,
            subscriptionSummary: summary,
            lastUpdatedAt: Date(),
            message: nil
        )
    }

    private func refreshAuthTokenIfNeeded(after error: Error) async -> Bool {
        guard let apiError = error as? Sub2APIError,
              apiError.isUnauthorized,
              !config.refreshToken.isEmpty else {
            return false
        }

        var refreshConfig = config
        refreshConfig.authToken = ""
        do {
            let response = try await Sub2APIClient(config: refreshConfig).refreshToken(config.refreshToken)
            var next = config
            next.authToken = response.accessToken
            next.refreshToken = response.refreshToken ?? config.refreshToken
            try store.save(next)
            let loaded = store.load()
            config = loaded
            settingsDraft = loaded
            return true
        } catch {
            return false
        }
    }

    private func publishDisconnected(_ error: Error) {
        publish(MonitorSnapshot(
            mode: config.monitorMode,
            connected: false,
            stats: nil,
            realtime: nil,
            accountHealth: nil,
            subscriptionSummary: nil,
            lastUpdatedAt: snapshot.lastUpdatedAt,
            message: error.localizedDescription
        ))
    }

    func saveSettings() {
        settingsError = nil
        var next = settingsDraft
        next.normalize()
        do {
            try store.save(next)
            let loaded = store.load()
            config = loaded
            settingsDraft = loaded
            scheduleTimer()
            onSnapshotChange?(snapshot)
            refresh()
        } catch {
            settingsError = error.localizedDescription
        }
    }

    func disconnect() {
        settingsError = nil
        var next = config
        let accountID = next.selectedAccountID
        next.accounts.removeAll { $0.id == accountID }
        next.selectedAccountID = next.accounts.first?.id
        if let selectedAccountID = next.selectedAccountID {
            let tokens = store.loadTokens(for: selectedAccountID)
            next.selectAccount(id: selectedAccountID, tokens: tokens)
        } else {
            next.clearAuthTokens()
        }
        do {
            if let accountID {
                try store.deleteTokens(for: accountID)
            }
            try store.save(next)
            let loaded = store.load()
            config = loaded
            settingsDraft = loaded
            loginEmail = loaded.selectedAccount?.email ?? ""
            loginPassword = ""
            if loaded.authToken.isEmpty {
                publish(.idle(mode: loaded.monitorMode))
            } else {
                refresh()
            }
        } catch {
            settingsError = error.localizedDescription
        }
    }

    func selectAccount(_ account: StoredAccount) {
        settingsError = nil
        var next = config
        let tokens = store.loadTokens(for: account.id)
        next.selectAccount(id: account.id, tokens: tokens)
        do {
            try store.save(next)
            let loaded = store.load()
            config = loaded
            settingsDraft = loaded
            loginEmail = loaded.selectedAccount?.email ?? ""
            loginPassword = ""
            onSnapshotChange?(snapshot)
            if loaded.authToken.isEmpty {
                publish(.idle(mode: loaded.monitorMode))
            } else {
                refresh()
            }
        } catch {
            settingsError = error.localizedDescription
        }
    }

    func loginAndSave() {
        settingsError = nil
        var draft = settingsDraft
        draft.authToken = ""
        let client = Sub2APIClient(config: draft)
        Task {
            isLoggingIn = true
            defer { isLoggingIn = false }
            do {
                let response = try await client.login(email: loginEmail, password: loginPassword)
                let tokens = StoredAuthTokens(authToken: response.accessToken, refreshToken: response.refreshToken ?? "")
                let displayName = response.user?.username ?? loginEmail
                settingsDraft.upsertAccount(
                    name: displayName,
                    email: response.user?.email ?? loginEmail,
                    baseURL: draft.baseURL,
                    tokens: tokens
                )
                loginPassword = ""
                saveSettings()
            } catch {
                settingsError = error.localizedDescription
            }
        }
    }

    func openDashboard() {
        openURL(config.baseURL)
    }

    func checkForUpdates(silent: Bool = false) {
        Task {
            await checkForUpdatesNow(silent: silent)
        }
    }

    func checkForUpdatesNow(silent: Bool = false) async {
        guard !isCheckingForUpdates else {
            return
        }

        isCheckingForUpdates = true
        if !silent {
            updateStatusMessage = nil
        }
        defer { isCheckingForUpdates = false }

        do {
            let info = try await updateChecker.check(currentVersion: currentAppVersion)
            updateInfo = info
            if info.isUpdateAvailable || !silent {
                updateStatusMessage = info.statusText
            }
        } catch {
            if !silent {
                updateStatusMessage = error.localizedDescription
            }
        }
    }

    func openLatestRelease() {
        if let releaseURL = updateInfo?.latestRelease.releaseURL {
            NSWorkspace.shared.open(releaseURL)
            return
        }
        openURL("https://github.com/\(AppBuildInfo.repositoryOwner)/\(AppBuildInfo.repositoryName)/releases")
    }

    func openURL(_ value: String) {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginEnabled = Self.currentLaunchAtLoginState()
        } catch {
            launchAtLoginEnabled = Self.currentLaunchAtLoginState()
            launchAtLoginError = error.localizedDescription
        }
    }

    func copyDiagnostics() {
        let report = DiagnosticReport.make(
            config: config,
            snapshot: snapshot,
            appVersion: currentAppVersion
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        updateStatusMessage = "Diagnostics copied."
    }

    func revealConfigFile() {
        NSWorkspace.shared.activateFileViewerSelecting([store.configurationFileURL])
    }

    func quit() {
        NSApp.terminate(nil)
    }

    var loginRecoverySuggestion: RecoverySuggestion {
        RecoverySuggestion.make(
            message: settingsError,
            hasBaseURL: !settingsDraft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasToken: !settingsDraft.authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    var snapshotRecoverySuggestion: RecoverySuggestion? {
        guard !snapshot.connected else {
            return nil
        }
        return RecoverySuggestion.make(
            message: snapshot.message,
            hasBaseURL: !config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasToken: !config.authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    func performRecoveryAction(_ action: RecoveryActionKind) {
        switch action {
        case .enterURL:
            settingsDraft.baseURL = settingsDraft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        case .openServer:
            openURL(settingsDraft.baseURL.isEmpty ? config.baseURL : settingsDraft.baseURL)
        case .login:
            loginPassword = ""
        case .replaceToken:
            focusesManualToken = true
        case .retry:
            refresh()
        }
    }

    private func publish(_ next: MonitorSnapshot) {
        snapshot = next
        onSnapshotChange?(next)
        notifyIfNeeded(for: next)
    }

    private func notifyIfNeeded(for snapshot: MonitorSnapshot) {
        guard snapshot.connected else {
            return
        }

        let insights = UsageInsights.make(
            currentUser: snapshot.currentUser,
            stats: snapshot.stats,
            subscriptionSummary: snapshot.subscriptionSummary,
            trend: snapshot.trend,
            models: snapshot.modelDistribution,
            thresholds: config.insightThresholds
        )
        insightNotifier.handle(insights: insights, settings: config.insightAlertSettings)
    }

    private var currentAppVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? AppBuildInfo.fallbackVersion
    }

    private func scheduleTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: config.refreshIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private static func lastSevenDayRange() -> (start: String, end: String) {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return (formatter.string(from: start), formatter.string(from: today))
    }

    private static func currentLaunchAtLoginState() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
}
