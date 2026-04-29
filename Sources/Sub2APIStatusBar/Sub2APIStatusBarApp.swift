import AppKit
import SwiftUI
import Sub2APIStatusCore

@main
struct Sub2APIStatusBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let model = MonitorViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "Sub2API")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 680)
        popover.contentViewController = NSHostingController(rootView: MonitorPanel(model: model))

        model.onSnapshotChange = { [weak self] snapshot in
            self?.updateStatusItem(snapshot)
        }
        model.start()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateStatusItem(_ snapshot: MonitorSnapshot) {
        guard let button = statusItem.button else {
            return
        }

        switch snapshot.severity {
        case .healthy:
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Sub2API OK")
        case .warning:
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Sub2API Warning")
        case .error:
            button.image = NSImage(systemSymbolName: "xmark.octagon", accessibilityDescription: "Sub2API Error")
        }
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.title = snapshot.connected && model.config.showsMenuBarText ? " \(snapshot.menuBarSummary)" : ""

        if let stats = snapshot.stats, snapshot.connected {
            button.toolTip = "Sub2API \(snapshot.statusLabel) - Today \(StatusFormatters.currency(stats.todayActualCost)), RPM \(String(format: "%.1f", stats.rpm))"
        } else {
            button.toolTip = "Sub2API \(snapshot.statusLabel)"
        }
    }
}

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

    var onSnapshotChange: ((MonitorSnapshot) -> Void)?

    private let store = ConfigStore()
    private let updateChecker = GitHubUpdateChecker()
    private var refreshTimer: Timer?

    init() {
        let loaded = store.load()
        config = loaded
        settingsDraft = loaded
        snapshot = .idle(mode: loaded.monitorMode)
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
            config = next
            settingsDraft = next
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
            config = next
            settingsDraft = next
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
        next.clearAuthTokens()
        do {
            try store.save(next)
            config = next
            settingsDraft = next
            loginEmail = ""
            loginPassword = ""
            publish(.idle(mode: next.monitorMode))
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
                settingsDraft.authToken = response.accessToken
                settingsDraft.refreshToken = response.refreshToken ?? ""
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

    func quit() {
        NSApp.terminate(nil)
    }

    private func publish(_ next: MonitorSnapshot) {
        snapshot = next
        onSnapshotChange?(next)
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
}

struct MonitorPanel: View {
    @ObservedObject var model: MonitorViewModel
    @State private var showingSettings = false

    var body: some View {
        Group {
            if model.config.authToken.isEmpty {
                LoginPanel(model: model)
            } else {
                VStack(spacing: 0) {
                    header
                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            statusSection

                            if let updateInfo = model.updateInfo, updateInfo.isUpdateAvailable {
                                UpdateAvailableBanner(info: updateInfo) {
                                    model.openLatestRelease()
                                }
                            }

                            userSection

                            if let message = model.snapshot.message, !message.isEmpty {
                                MessageRow(message: message)
                            }
                        }
                        .padding(16)
                    }

                    Divider()
                    footer
                }
            }
        }
        .frame(width: 520, height: 680)
        .sheet(isPresented: $showingSettings) {
            SettingsView(model: model)
                .frame(width: 430, height: 610)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sub2API")
                    .font(.headline)
                Text(model.snapshot.connected ? lastUpdatedText : "Disconnected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.refresh()
            } label: {
                Image(systemName: model.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
            }
            .disabled(model.isRefreshing)
            .help("Refresh")

            Button {
                model.settingsDraft = model.config
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .help("Settings")
        }
        .buttonStyle(.borderless)
        .padding(16)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.snapshot.statusLabel)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(iconColor)
                Spacer()
                Text("User Usage")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            if model.config.authToken.isEmpty {
                Text("Set Base URL and token to start monitoring.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var userSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let user = model.snapshot.currentUser {
                UserAccountCard(user: user)
            }

            if let stats = model.snapshot.stats {
                MetricGrid(items: [
                    MetricItem(title: "Balance", value: balanceText, caption: "Available", systemImage: "banknote", tint: .green),
                    MetricItem(title: "API Keys", value: "\(stats.totalAPIKeys)", caption: "\(stats.activeAPIKeys) active", systemImage: "key", tint: .blue),
                    MetricItem(title: "Today Requests", value: StatusFormatters.menuBarCount(stats.todayRequests), caption: "Total \(StatusFormatters.compactNumber(stats.totalRequests))", systemImage: "chart.bar", tint: .green),
                    MetricItem(title: "Today Cost", value: StatusFormatters.preciseCurrency(stats.todayActualCost), caption: "Total \(StatusFormatters.preciseCurrency(stats.totalActualCost))", systemImage: "dollarsign.circle", tint: .purple),
                    MetricItem(title: "Today Tokens", value: StatusFormatters.compactNumber(stats.todayTokens), caption: tokenBreakdown(input: stats.todayInputTokens, output: stats.todayOutputTokens), systemImage: "cube", tint: .orange),
                    MetricItem(title: "Total Tokens", value: StatusFormatters.compactNumber(stats.totalTokens), caption: tokenBreakdown(input: stats.totalInputTokens, output: stats.totalOutputTokens), systemImage: "archivebox.fill", tint: .indigo),
                    MetricItem(title: "Performance", value: "\(StatusFormatters.menuBarRate(stats.rpm)) RPM", caption: "\(StatusFormatters.compactNumber(Int64(stats.tpm))) TPM", systemImage: "bolt", tint: .purple),
                    MetricItem(title: "Avg Response", value: latencyText(milliseconds: stats.averageDurationMs), caption: "Average time", systemImage: "clock", tint: .pink),
                ])
            }

            if let summary = model.snapshot.subscriptionSummary {
                if model.snapshot.stats == nil {
                    MetricGrid(items: [
                        MetricItem(title: "Balance", value: balanceText, systemImage: "banknote", tint: .green),
                        MetricItem(title: "Active Subs", value: "\(summary.activeCount)", systemImage: "checkmark.seal", tint: .green),
                        MetricItem(title: "Peak Usage", value: StatusFormatters.percent(summary.highestProgress), systemImage: "gauge.with.dots.needle.67percent", tint: .orange),
                        MetricItem(title: "Total Used", value: StatusFormatters.preciseCurrency(summary.totalUsedUSD), systemImage: "dollarsign.circle", tint: .purple),
                    ])
                }

                SectionBlock(title: "Subscriptions") {
                    VStack(spacing: 10) {
                        ForEach(summary.subscriptions.prefix(5)) { item in
                            SubscriptionQuotaCard(item: item)
                        }
                    }
                }
            }

            if let models = model.snapshot.modelDistribution, !models.isEmpty {
                ModelDistributionView(models: models)
            }

            if let trend = model.snapshot.trend, trend.count > 1 {
                SectionBlock(title: "Token Trend") {
                    TokenTrendView(points: trend)
                        .frame(height: 150)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                model.openDashboard()
            } label: {
                Label("Open", systemImage: "safari")
            }
            .disabled(model.config.baseURL.isEmpty)

            Spacer()

            Button {
                model.quit()
            } label: {
                Label("Quit", systemImage: "power")
            }
        }
        .buttonStyle(.borderless)
        .padding(12)
    }

    private var iconName: String {
        switch model.snapshot.severity {
        case .healthy:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch model.snapshot.severity {
        case .healthy:
            .green
        case .warning:
            .orange
        case .error:
            .red
        }
    }

    private var lastUpdatedText: String {
        guard let date = model.snapshot.lastUpdatedAt else {
            return "Waiting for first refresh"
        }
        return "Updated \(date.formatted(date: .omitted, time: .shortened))"
    }

    private var balanceText: String {
        guard let balance = model.snapshot.currentUser?.balance else {
            return "--"
        }
        return StatusFormatters.currency(balance)
    }

    private func tokenBreakdown(input: Int64, output: Int64) -> String {
        "In \(StatusFormatters.compactNumber(input)) / Out \(StatusFormatters.compactNumber(output))"
    }

    private func latencyText(milliseconds: Double) -> String {
        if milliseconds >= 1_000 {
            return String(format: "%.2fs", milliseconds / 1_000)
        }
        return "\(Int(milliseconds))ms"
    }

}

struct LoginPanel: View {
    @ObservedObject var model: MonitorViewModel

    private var formState: LoginFormState {
        LoginFormState(
            baseURL: model.settingsDraft.baseURL,
            email: model.loginEmail,
            password: model.loginPassword
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sub2API")
                        .font(.title2.bold())
                    Text("Connect your server")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                TextField("Server URL", text: $model.settingsDraft.baseURL)
                    .textFieldStyle(.roundedBorder)

                TextField("Account", text: $model.loginEmail)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $model.loginPassword)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("Refresh")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Slider(value: $model.settingsDraft.refreshIntervalSeconds, in: 5...300, step: 5)
                    Text("\(Int(model.settingsDraft.refreshIntervalSeconds))s")
                        .font(.callout.monospacedDigit())
                        .frame(width: 42, alignment: .trailing)
                }
            }

            if let error = model.settingsError {
                MessageRow(message: error)
            }

            Button {
                model.loginAndSave()
            } label: {
                HStack {
                    if model.isLoggingIn {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "key.fill")
                    }
                    Text(model.isLoggingIn ? "Connecting..." : "Login")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!formState.canSubmit || model.isLoggingIn)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Manual token")
                    .font(.headline)
                SecureField("Bearer Token", text: $model.settingsDraft.authToken)
                    .textFieldStyle(.roundedBorder)
                Button {
                    model.saveSettings()
                } label: {
                    Label("Save Token", systemImage: "square.and.arrow.down")
                }
                .disabled(model.settingsDraft.authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()

            HStack {
                Button {
                    model.openURL(model.settingsDraft.baseURL)
                } label: {
                    Label("Open Server", systemImage: "safari")
                }
                .disabled(model.settingsDraft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Button {
                    model.quit()
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(20)
    }
}

struct SettingsView: View {
    @ObservedObject var model: MonitorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.bold())

            Form {
                TextField("Base URL", text: $model.settingsDraft.baseURL)
                Toggle("Show text in menu bar", isOn: $model.settingsDraft.showsMenuBarText)
                HStack {
                    Slider(value: $model.settingsDraft.refreshIntervalSeconds, in: 5...300, step: 5)
                    Text("\(Int(model.settingsDraft.refreshIntervalSeconds))s")
                        .frame(width: 42, alignment: .trailing)
                }
                SecureField("Bearer Token", text: $model.settingsDraft.authToken)
            }

            Divider()

            UpdateSettingsSection(model: model)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Login")
                    .font(.headline)
                TextField("Email", text: $model.loginEmail)
                SecureField("Password", text: $model.loginPassword)
                Button {
                    model.loginAndSave()
                } label: {
                    Label("Login and Save Token", systemImage: "key")
                }
                .disabled(!LoginFormState(baseURL: model.settingsDraft.baseURL, email: model.loginEmail, password: model.loginPassword).canSubmit || model.isLoggingIn)

                Button(role: .destructive) {
                    model.disconnect()
                    dismiss()
                } label: {
                    Label("Disconnect", systemImage: "person.crop.circle.badge.xmark")
                }
                .disabled(model.config.authToken.isEmpty && model.settingsDraft.authToken.isEmpty)
            }

            if let error = model.settingsError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    model.saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }
}

struct UpdateSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Updates")
                    .font(.headline)
                Spacer()
                if model.isCheckingForUpdates {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let updateInfo = model.updateInfo, updateInfo.isUpdateAvailable {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(updateInfo.statusText)
                            .font(.callout.weight(.medium))
                        Text(updateInfo.latestRelease.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else if let message = model.updateStatusMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Checks GitHub Releases for newer versions.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    model.checkForUpdates()
                } label: {
                    Label("Check Now", systemImage: "arrow.clockwise")
                }
                .disabled(model.isCheckingForUpdates)

                if model.updateInfo?.isUpdateAvailable == true {
                    Button {
                        model.openLatestRelease()
                    } label: {
                        Label("Open Release", systemImage: "safari")
                    }
                }
            }
            .buttonStyle(.borderless)
        }
    }
}

struct UpdateAvailableBanner: View {
    let info: UpdateInfo
    let openRelease: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(info.statusText)
                    .font(.callout.weight(.semibold))
                Text("Download the latest release from GitHub.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                openRelease()
            } label: {
                Image(systemName: "safari")
            }
            .buttonStyle(.borderless)
            .help("Open release")
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MetricItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String?
    let systemImage: String?
    let tint: Color

    init(title: String, value: String, caption: String? = nil, systemImage: String? = nil, tint: Color = .accentColor) {
        self.title = title
        self.value = value
        self.caption = caption
        self.systemImage = systemImage
        self.tint = tint
    }
}

struct UserAccountCard: View {
    let user: CurrentUser

    private var displayName: String {
        guard let username = user.username, !username.isEmpty else {
            return user.email
        }
        return username
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            if let status = user.status, !status.isEmpty {
                Text(status.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(status.lowercased() == "active" ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((status.lowercased() == "active" ? Color.green : Color.secondary).opacity(0.14), in: Capsule())
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MetricGrid: View {
    let items: [MetricItem]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(items) { item in
                HStack(spacing: 10) {
                    if let systemImage = item.systemImage {
                        SafeSystemImage(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(item.tint)
                            .frame(width: 32, height: 32)
                            .background(item.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.value)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if let caption = item.caption {
                            Text(caption)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct SafeSystemImage: View {
    let systemName: String
    var fallbackName = "circle.grid.3x3.fill"

    var body: some View {
        if let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: fallbackName, accessibilityDescription: nil) {
            Image(nsImage: image)
                .renderingMode(.template)
        } else {
            Image(systemName: "questionmark.circle")
        }
    }
}

struct SubscriptionQuotaCard: View {
    let item: SubscriptionSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(item.status == "active" ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(item.groupName)
                    .font(.headline)
                Spacer()
                Text(item.status == "active" ? "Active" : item.status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(item.status == "active" ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((item.status == "active" ? Color.green : Color.secondary).opacity(0.14), in: Capsule())
            }

            if let days = item.daysRemaining {
                HStack {
                    Text("Expires")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Remaining \(days)d")
                }
                .font(.caption)
            }

            QuotaProgressRow(
                title: "Daily",
                used: item.dailyUsedUSD,
                limit: item.dailyLimitUSD,
                progress: item.dailyProgress,
                resetInSeconds: item.dailyResetInSeconds
            )
            QuotaProgressRow(
                title: "Weekly",
                used: item.weeklyUsedUSD,
                limit: item.weeklyLimitUSD,
                progress: item.weeklyProgress,
                resetInSeconds: item.weeklyResetInSeconds
            )
            QuotaProgressRow(
                title: "Monthly",
                used: item.monthlyUsedUSD,
                limit: item.monthlyLimitUSD,
                progress: item.monthlyProgress,
                resetInSeconds: item.monthlyResetInSeconds
            )
        }
    }
}

struct QuotaProgressRow: View {
    let title: String
    let used: Double?
    let limit: Double?
    let progress: Double?
    let resetInSeconds: Double?

    private var normalizedProgress: Double {
        min(max(progress ?? 0, 0), 1)
    }

    private var tint: Color {
        normalizedProgress >= 0.95 ? .red : .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.callout.weight(.semibold))
                Spacer()
                Text(amountText)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            ProgressView(value: normalizedProgress)
                .tint(tint)

            if let resetInSeconds {
                Text("\(StatusFormatters.duration(seconds: resetInSeconds)) until reset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var amountText: String {
        guard let used, let limit else {
            return "--"
        }
        return "\(StatusFormatters.currency(used)) / \(StatusFormatters.currency(limit))"
    }
}

struct ModelDistributionView: View {
    let models: [ModelUsageSummary]

    private var visibleModels: [ModelUsageSummary] {
        Array(models.prefix(5))
    }

    private var maximumTokens: Double {
        max(Double(visibleModels.map(\.totalTokens).max() ?? 0), 1)
    }

    var body: some View {
        SectionBlock(title: "Model Distribution") {
            VStack(spacing: 10) {
                ForEach(visibleModels) { item in
                    VStack(spacing: 7) {
                        HStack {
                            Text(item.model)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Spacer()
                            Text(StatusFormatters.preciseCurrency(item.actualCost))
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.green)
                        }
                        HStack {
                            Text("\(StatusFormatters.menuBarCount(item.requests)) requests")
                            Spacer()
                            Text(StatusFormatters.compactNumber(item.totalTokens))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        ProgressView(value: Double(item.totalTokens) / maximumTokens)
                            .tint(.blue)
                    }
                    if item.id != visibleModels.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct TokenTrendView: View {
    let points: [TrendDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                ZStack {
                    trendPath(values: points.map { Double($0.cacheReadTokens) }, in: proxy.size)
                        .fill(Color.cyan.opacity(0.16))
                    trendPath(values: points.map { Double($0.cacheReadTokens) }, in: proxy.size)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    trendPath(values: points.map { Double($0.inputTokens) }, in: proxy.size)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    trendPath(values: points.map { Double($0.outputTokens) }, in: proxy.size)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }

            HStack(spacing: 12) {
                LegendDot(color: .blue, label: "Input")
                LegendDot(color: .green, label: "Output")
                LegendDot(color: .cyan, label: "Cache Read")
                Spacer()
                Text(points.last?.date ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)
        }
    }

    private func trendPath(values: [Double], in size: CGSize) -> Path {
        let maximum = max(values.max() ?? 0, 1)
        var path = Path()
        for index in values.indices {
            let x = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
            let y = size.height - (size.height * CGFloat(values[index] / maximum))
            if index == values.startIndex {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
        }
    }
}

struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}

struct MessageRow: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
