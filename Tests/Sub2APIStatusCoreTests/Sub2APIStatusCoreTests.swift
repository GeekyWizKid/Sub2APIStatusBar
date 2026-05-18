import Foundation
import Testing
@testable import Sub2APIStatusCore

@Test func appConfigNormalizesBaseURLAndRefreshInterval() {
    var config = AppConfig(baseURL: " http://127.0.0.1:8080/api/v1/// ", authToken: " token ", refreshIntervalSeconds: 1, language: .zhHans, monitorMode: .user)

    config.normalize()

    #expect(config.baseURL == "http://127.0.0.1:8080")
    #expect(config.authToken == "token")
    #expect(config.refreshIntervalSeconds == 5)
    #expect(config.monitorMode == .user)
    #expect(config.showsMenuBarText == false)
}

@Test func appConfigPersistsMenuBarTextPreference() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let store = ConfigStore(configURL: configURL)
    let config = AppConfig(baseURL: "http://127.0.0.1:8080", showsMenuBarText: true)

    try store.save(config)
    let loaded = store.load()

    #expect(loaded.baseURL == "http://127.0.0.1:8080")
    #expect(loaded.showsMenuBarText == true)
}

@Test func appConfigPersistsInsightThresholds() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let store = ConfigStore(configURL: configURL)
    var thresholds = InsightThresholds.defaults
    thresholds.quotaWarningProgress = 0.7
    thresholds.quotaCriticalProgress = 0.9
    thresholds.lowBalanceDays = 5
    thresholds.tokenSurgeRatio = 1.25
    thresholds.modelConcentrationShare = 0.65
    thresholds.latencyWarningMs = 18_000

    try store.save(AppConfig(baseURL: "https://sub2api.example.com", insightThresholds: thresholds))
    let loaded = store.load()

    #expect(loaded.insightThresholds.quotaWarningProgress == 0.7)
    #expect(loaded.insightThresholds.quotaCriticalProgress == 0.9)
    #expect(loaded.insightThresholds.lowBalanceDays == 5)
    #expect(loaded.insightThresholds.tokenSurgeRatio == 1.25)
    #expect(loaded.insightThresholds.modelConcentrationShare == 0.65)
    #expect(loaded.insightThresholds.latencyWarningMs == 18_000)
}

@Test func appConfigPersistsInsightAlertSettings() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let store = ConfigStore(configURL: configURL)
    let settings = InsightAlertSettings(
        isEnabled: false,
        minimumSeverity: .error,
        cooldownMinutes: 120
    )

    try store.save(AppConfig(baseURL: "https://sub2api.example.com", insightAlertSettings: settings))
    let loaded = store.load()

    #expect(loaded.insightAlertSettings.isEnabled == false)
    #expect(loaded.insightAlertSettings.minimumSeverity == .error)
    #expect(loaded.insightAlertSettings.cooldownMinutes == 120)
}

@Test func insightAlertSettingsNormalizeUnsafeValues() {
    var settings = InsightAlertSettings(
        isEnabled: true,
        minimumSeverity: .warning,
        cooldownMinutes: 2
    )

    settings.normalize()

    #expect(settings.cooldownMinutes == 5)

    settings.cooldownMinutes = 2_000
    settings.normalize()

    #expect(settings.cooldownMinutes == 1_440)
}

@Test func insightNotificationPermissionSummarizesActionableStates() {
    let ready = InsightNotificationPermissionSummary.make(settings: .defaults, authorization: .authorized)
    let notDetermined = InsightNotificationPermissionSummary.make(settings: .defaults, authorization: .notDetermined)
    let denied = InsightNotificationPermissionSummary.make(settings: .defaults, authorization: .denied)
    let disabled = InsightNotificationPermissionSummary.make(
        settings: InsightAlertSettings(isEnabled: false, minimumSeverity: .warning, cooldownMinutes: 60),
        authorization: .authorized
    )

    #expect(ready.title == "Notifications ready")
    #expect(ready.detail == "macOS alerts can be delivered for warning insights.")
    #expect(ready.action == nil)
    #expect(notDetermined.title == "Permission needed")
    #expect(notDetermined.action == .requestPermission)
    #expect(denied.title == "Notifications blocked")
    #expect(denied.action == .openSystemSettings)
    #expect(disabled.title == "Alerts off")
    #expect(disabled.detail == "Turn on insight alerts to receive local notifications.")
    #expect(disabled.action == nil)
}

@Test func insightThresholdsNormalizeUnsafeValues() {
    var thresholds = InsightThresholds(
        quotaWarningProgress: 1.4,
        quotaCriticalProgress: 0.2,
        lowBalanceDays: -5,
        tokenSurgeRatio: 0.9,
        modelConcentrationShare: 2,
        latencyWarningMs: 500
    )

    thresholds.normalize()

    #expect(thresholds.quotaWarningProgress == 0.8)
    #expect(thresholds.quotaCriticalProgress == 0.95)
    #expect(thresholds.lowBalanceDays == 1)
    #expect(thresholds.tokenSurgeRatio == 1.1)
    #expect(thresholds.modelConcentrationShare == 0.8)
    #expect(thresholds.latencyWarningMs == 1_000)
}

@Test func configStoreSavesTokensInConfigJSON() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let store = ConfigStore(configURL: configURL)
    let config = AppConfig(
        baseURL: "http://127.0.0.1:8080",
        authToken: "access-token",
        refreshToken: "refresh-token",
        showsMenuBarText: true
    )

    try store.save(config)

    let rawJSON = try String(contentsOf: configURL, encoding: .utf8)
    #expect(rawJSON.contains("access-token"))
    #expect(rawJSON.contains("refresh-token"))
    #expect(rawJSON.contains("authToken"))
    #expect(rawJSON.contains("refreshToken"))
    #expect(store.load().authToken == "access-token")
    #expect(store.load().refreshToken == "refresh-token")
    #expect(store.load().accounts.first?.authToken == "access-token")
    #expect(store.load().accounts.first?.refreshToken == "refresh-token")
}

@Test func configStoreCanUseEnvironmentConfigPath() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("demo-config.json")
    let store = ConfigStore(environment: ["SUB2API_CONFIG_PATH": configURL.path])

    try store.save(AppConfig(baseURL: "https://sub2api.example.com", authToken: "demo-token"))

    #expect(store.configurationFileURL == configURL)
    #expect(FileManager.default.fileExists(atPath: configURL.path))
    #expect(store.load().authToken == "demo-token")
}

@Test func configStoreLoadsLegacyJSONTokensIntoDefaultAccount() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try """
    {
      "baseURL" : "http://127.0.0.1:8080",
      "authToken" : "legacy-access",
      "refreshToken" : "legacy-refresh",
      "refreshIntervalSeconds" : 15,
      "language" : "auto",
      "monitorMode" : "user",
      "showsMenuBarText" : true
    }
    """.write(to: configURL, atomically: true, encoding: .utf8)
    let store = ConfigStore(configURL: configURL)

    let loaded = store.load()

    #expect(loaded.authToken == "legacy-access")
    #expect(loaded.refreshToken == "legacy-refresh")
    #expect(loaded.accounts.count == 1)
    #expect(loaded.accounts.first?.baseURL == "http://127.0.0.1:8080")
    #expect(loaded.accounts.first?.authToken == "legacy-access")
    #expect(loaded.accounts.first?.refreshToken == "legacy-refresh")
}

@Test func configStoreSwitchesBetweenAccountTokensInConfigJSON() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let first = StoredAccount(
        id: "first",
        name: "First",
        email: "first@example.com",
        baseURL: "http://one.example.com",
        authToken: "first-access",
        refreshToken: "first-refresh"
    )
    let second = StoredAccount(
        id: "second",
        name: "Second",
        email: "second@example.com",
        baseURL: "http://two.example.com/api/v1",
        authToken: "second-access",
        refreshToken: "second-refresh"
    )
    let store = ConfigStore(configURL: configURL)
    try store.save(AppConfig(
        baseURL: first.baseURL,
        authToken: "first-access",
        refreshToken: "first-refresh",
        refreshIntervalSeconds: 30,
        accounts: [first, second],
        selectedAccountID: first.id
    ))

    var loaded = store.load()
    #expect(loaded.selectedAccountID == first.id)
    #expect(loaded.baseURL == "http://one.example.com")
    #expect(loaded.authToken == "first-access")

    loaded.selectAccount(id: second.id, tokens: store.loadTokens(for: second.id))
    try store.save(loaded)
    let switched = store.load()

    #expect(switched.selectedAccountID == second.id)
    #expect(switched.baseURL == "http://two.example.com")
    #expect(switched.authToken == "second-access")
    #expect(switched.refreshToken == "second-refresh")
    #expect(switched.accounts.count == 2)
}

@Test func appConfigDefaultsToUserMode() {
    let config = AppConfig(baseURL: "http://127.0.0.1:8080")

    #expect(config.monitorMode == .user)
}

@Test func appConfigDecodesLegacyAdminModeAsUserMode() throws {
    let data = """
    {
      "baseURL": "http://127.0.0.1:8080",
      "monitorMode": "admin"
    }
    """.data(using: .utf8)!

    let config = try JSONDecoder.sub2api.decode(AppConfig.self, from: data)

    #expect(config.monitorMode == .user)
}

@Test func appConfigClearsAuthTokens() {
    var config = AppConfig(baseURL: "http://127.0.0.1:8080", authToken: "access", refreshToken: "refresh")

    config.clearAuthTokens()

    #expect(config.authToken.isEmpty)
    #expect(config.refreshToken.isEmpty)
}

@Test func apiEnvelopeDecodesWrappedData() throws {
    let json = """
    {
      "code": 0,
      "message": "ok",
      "data": {
        "active_requests": 2,
        "requests_per_minute": 13.5,
        "average_response_time": 840,
        "error_rate": 0.025
      }
    }
    """.data(using: .utf8)!

    let metrics = try JSONDecoder.sub2api.decode(Sub2APIEnvelope<RealtimeMetrics>.self, from: json).value()

    #expect(metrics.activeRequests == 2)
    #expect(metrics.requestsPerMinute == 13.5)
    #expect(metrics.averageResponseTime == 840)
    #expect(metrics.errorRate == 0.025)
}

@Test func sub2APIErrorIdentifiesUnauthorizedResponses() {
    #expect(Sub2APIError.badStatus(401, "expired").isUnauthorized == true)
    #expect(Sub2APIError.badStatus(403, "forbidden").isUnauthorized == false)
    #expect(Sub2APIError.invalidBaseURL.isUnauthorized == false)
}

@Test func recoverySuggestionMapsCommonConnectionFailures() {
    let invalidURL = RecoverySuggestion.make(
        message: Sub2APIError.invalidBaseURL.localizedDescription,
        hasBaseURL: false,
        hasToken: false
    )
    let unauthorized = RecoverySuggestion.make(
        message: Sub2APIError.badStatus(401, "expired").localizedDescription,
        hasBaseURL: true,
        hasToken: true
    )
    let serverDown = RecoverySuggestion.make(
        message: "The request timed out.",
        hasBaseURL: true,
        hasToken: true
    )

    #expect(invalidURL.title == "Add your server URL")
    #expect(invalidURL.actions.map(\.label) == ["Enter URL", "Open Server"])
    #expect(unauthorized.title == "Sign in again")
    #expect(unauthorized.actions.map(\.label) == ["Login", "Replace Token"])
    #expect(serverDown.title == "Check server reachability")
    #expect(serverDown.actions.map(\.label) == ["Open Server", "Retry"])
}

@Test func appVersionComparesSemanticVersions() {
    #expect(AppVersion("v0.1.10") > AppVersion("0.1.2"))
    #expect(AppVersion("1.0") == AppVersion("1.0.0"))
    #expect(AppVersion("v2.0.0-beta") > AppVersion("1.9.9"))
}

@Test func githubReleaseDecodesLatestReleasePayload() throws {
    let json = """
    {
      "tag_name": "v0.1.3",
      "name": "Sub2API Status Bar v0.1.3",
      "html_url": "https://github.com/GeekyWizKid/Sub2APIStatusBar/releases/tag/v0.1.3",
      "draft": false,
      "prerelease": false
    }
    """.data(using: .utf8)!

    let release = try JSONDecoder().decode(GitHubRelease.self, from: json)

    #expect(release.tagName == "v0.1.3")
    #expect(release.version == AppVersion("0.1.3"))
    #expect(release.releaseURL.absoluteString.hasSuffix("/v0.1.3"))
}

@Test func updateInfoDetectsAvailableRelease() {
    let release = GitHubRelease(
        tagName: "v0.1.3",
        name: "Sub2API Status Bar v0.1.3",
        releaseURL: URL(string: "https://github.com/GeekyWizKid/Sub2APIStatusBar/releases/tag/v0.1.3")!,
        draft: false,
        prerelease: false
    )

    let available = UpdateInfo(currentVersion: AppVersion("0.1.2"), release: release)
    let current = UpdateInfo(currentVersion: AppVersion("0.1.3"), release: release)

    #expect(available.isUpdateAvailable == true)
    #expect(available.statusText == "Version 0.1.3 is available.")
    #expect(current.isUpdateAvailable == false)
    #expect(current.statusText == "You are up to date.")
}

@Test func currentUserResponseDecodesDirectUserPayload() throws {
    let json = """
    {
      "id": 7,
      "email": "user@example.com",
      "username": "das",
      "role": "user",
      "balance": 12.34,
      "status": "active"
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder.sub2api.decode(CurrentUserResponse.self, from: json)

    #expect(response.user?.balance == 12.34)
    #expect(response.user?.username == "das")
}

@Test func dashboardSnapshotDecodesTokenBreakdownAndModelDistribution() throws {
    let json = """
    {
      "generated_at": "2026-04-28T13:00:00Z",
      "stats": {
        "today_requests": 1119,
        "today_tokens": 121800000,
        "today_input_tokens": 7400000,
        "today_output_tokens": 513900,
        "total_tokens": 594300000,
        "total_input_tokens": 40200000,
        "total_output_tokens": 3500000,
        "today_actual_cost": 113.3052,
        "rpm": 3,
        "tpm": 12200,
        "average_duration_ms": 14570
      },
      "model_distribution": [
        {
          "model": "gpt-5.5",
          "requests": 2116,
          "total_tokens": 244400000,
          "input_tokens": 200000000,
          "output_tokens": 44400000,
          "actual_cost": 218.2116,
          "standard_cost": 218.2116
        }
      ]
    }
    """.data(using: .utf8)!

    let snapshot = try JSONDecoder.sub2api.decode(DashboardSnapshot.self, from: json)

    #expect(snapshot.stats?.todayInputTokens == 7_400_000)
    #expect(snapshot.stats?.todayOutputTokens == 513_900)
    #expect(snapshot.stats?.totalInputTokens == 40_200_000)
    #expect(snapshot.stats?.totalOutputTokens == 3_500_000)
    #expect(snapshot.modelDistribution?.first?.model == "gpt-5.5")
    #expect(snapshot.modelDistribution?.first?.requests == 2116)
    #expect(snapshot.modelDistribution?.first?.actualCost == 218.2116)
}

@Test func usageDashboardDecodesUserStatsTrendAndModels() throws {
    let statsJSON = """
    {
      "total_api_keys": 2,
      "active_api_keys": 2,
      "total_requests": 5476,
      "total_input_tokens": 40529619,
      "total_output_tokens": 3499464,
      "total_cache_creation_tokens": 0,
      "total_cache_read_tokens": 554867072,
      "total_tokens": 598896155,
      "total_cost": 498.69043735,
      "total_actual_cost": 498.69043735,
      "today_requests": 1186,
      "today_input_tokens": 7657045,
      "today_output_tokens": 536098,
      "today_cache_creation_tokens": 0,
      "today_cache_read_tokens": 118193024,
      "today_tokens": 126386167,
      "today_cost": 117.56682985,
      "today_actual_cost": 117.56682985,
      "average_duration_ms": 14514.6375,
      "rpm": 1,
      "tpm": 10752
    }
    """.data(using: .utf8)!
    let trendJSON = """
    {
      "trend": [
        {
          "date": "2026-04-28",
          "requests": 1187,
          "input_tokens": 7672001,
          "output_tokens": 536486,
          "cache_creation_tokens": 0,
          "cache_read_tokens": 118310656,
          "total_tokens": 126519143,
          "cost": 117.71206585,
          "actual_cost": 117.71206585
        }
      ]
    }
    """.data(using: .utf8)!
    let modelsJSON = """
    {
      "models": [
        {
          "model": "gpt-5.5",
          "requests": 2184,
          "input_tokens": 14103149,
          "output_tokens": 1004490,
          "cache_creation_tokens": 0,
          "cache_read_tokens": 234003712,
          "total_tokens": 249111351,
          "cost": 222.61852,
          "actual_cost": 222.61852,
          "account_cost": 222.61852
        }
      ]
    }
    """.data(using: .utf8)!

    let stats = try JSONDecoder.sub2api.decode(DashboardStats.self, from: statsJSON)
    let trend = try JSONDecoder.sub2api.decode(DashboardTrendResponse.self, from: trendJSON)
    let models = try JSONDecoder.sub2api.decode(DashboardModelsResponse.self, from: modelsJSON)

    #expect(stats.todayCacheReadTokens == 118_193_024)
    #expect(stats.todayCost == 117.56682985)
    #expect(trend.trend.first?.inputTokens == 7_672_001)
    #expect(trend.trend.first?.cacheReadTokens == 118_310_656)
    #expect(models.models.first?.accountCost == 222.61852)
    #expect(models.models.first?.standardCost == 222.61852)
}

@Test func tokenTrendDisplayShowsChartOnlyWhenEnoughPointsExist() {
    let first = TrendDataPoint(
        date: "2026-05-17",
        requests: 10,
        inputTokens: 100,
        outputTokens: 20,
        cacheCreationTokens: 0,
        cacheReadTokens: 40,
        totalTokens: 160,
        cost: 0.1,
        actualCost: 0.1
    )
    let second = TrendDataPoint(
        date: "2026-05-18",
        requests: 20,
        inputTokens: 200,
        outputTokens: 30,
        cacheCreationTokens: 0,
        cacheReadTokens: 80,
        totalTokens: 310,
        cost: 0.2,
        actualCost: 0.2
    )

    #expect(TokenTrendDisplayState.make(points: nil) == .unavailable("Trend data is not available yet."))
    #expect(TokenTrendDisplayState.make(points: []) == .unavailable("Trend data is not available yet."))
    #expect(TokenTrendDisplayState.make(points: [first]) == .unavailable("Trend data is not available yet."))
    #expect(TokenTrendDisplayState.make(points: [first, second]) == .chart([first, second]))
}

@Test func accountHealthSummaryCountsRuntimeStates() {
    let accounts = [
        AccountSummary(id: 1, name: "ok", platform: "openai", type: "oauth", status: "active", schedulable: true, quotaLimit: 100, quotaUsed: 30, quotaDailyLimit: nil, quotaDailyUsed: nil, quotaWeeklyLimit: nil, quotaWeeklyUsed: nil, errorMessage: "", rateLimitResetAt: nil),
        AccountSummary(id: 2, name: "blocked", platform: "openai", type: "oauth", status: "active", schedulable: false, quotaLimit: 100, quotaUsed: 91, quotaDailyLimit: nil, quotaDailyUsed: nil, quotaWeeklyLimit: nil, quotaWeeklyUsed: nil, errorMessage: "", rateLimitResetAt: nil),
        AccountSummary(id: 3, name: "bad", platform: "anthropic", type: "setup_token", status: "disabled", schedulable: false, quotaLimit: nil, quotaUsed: nil, quotaDailyLimit: nil, quotaDailyUsed: nil, quotaWeeklyLimit: nil, quotaWeeklyUsed: nil, errorMessage: "expired", rateLimitResetAt: nil),
    ]

    let summary = AccountHealthSummary(accounts: accounts)

    #expect(summary.total == 3)
    #expect(summary.active == 2)
    #expect(summary.schedulable == 1)
    #expect(summary.blocked == 2)
    #expect(summary.nearQuotaLimit == 1)
}

@Test func subscriptionProgressFindsHighestUsageRatio() {
    let subscriptions = [
        SubscriptionSummaryItem(id: 1, groupName: "Claude", status: "active", dailyProgress: 0.25, weeklyProgress: nil, monthlyProgress: 0.6, expiresAt: nil, daysRemaining: 12),
        SubscriptionSummaryItem(id: 2, groupName: "OpenAI", status: "active", dailyProgress: 0.82, weeklyProgress: 0.71, monthlyProgress: nil, expiresAt: nil, daysRemaining: 2),
    ]

    let summary = SubscriptionSummary(activeCount: 2, subscriptions: subscriptions)

    #expect(summary.highestProgress == 0.82)
    #expect(summary.expiringSoonCount == 1)
}

@Test func subscriptionSummaryDecodesUsdUsageIntoProgress() throws {
    let json = """
    {
      "active_count": 1,
      "total_used_usd": 498.38329835,
      "subscriptions": [
        {
          "id": 2,
          "group_name": "codex",
          "status": "active",
          "daily_used_usd": 117.25969085,
          "daily_limit_usd": 124.97,
          "weekly_used_usd": 153.11513095,
          "weekly_limit_usd": 500,
          "monthly_used_usd": 498.38329835,
          "monthly_limit_usd": 2000,
          "daily_reset_in_seconds": 6960,
          "weekly_reset_in_seconds": 435660,
          "monthly_reset_in_seconds": 1821660,
          "days_remaining": 22,
          "expires_at": "2026-05-20T16:29:44+08:00"
        }
      ]
    }
    """.data(using: .utf8)!

    let summary = try JSONDecoder.sub2api.decode(SubscriptionSummary.self, from: json)

    #expect(summary.totalUsedUSD == 498.38329835)
    #expect(summary.subscriptions.first?.dailyProgress ?? 0 > 0.93)
    #expect(summary.subscriptions.first?.monthlyProgress ?? 0 > 0.24)
    #expect(summary.subscriptions.first?.dailyResetInSeconds == 6960)
    #expect(summary.subscriptions.first?.daysRemaining == 22)
}

@Test func monitorSnapshotEscalatesSeverityFromSignals() {
    let healthy = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayRequests: 20, todayActualCost: 1.2, rpm: 4),
        realtime: RealtimeMetrics(errorRate: 0.01),
        accountHealth: AccountHealthSummary(accounts: []),
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )

    let warned = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayRequests: 20, todayActualCost: 1.2, rpm: 4),
        realtime: RealtimeMetrics(errorRate: 0.01),
        accountHealth: AccountHealthSummary(accounts: [
            AccountSummary(id: 1, name: "quota", platform: "openai", type: "oauth", status: "active", schedulable: true, quotaLimit: 10, quotaUsed: 9.1, quotaDailyLimit: nil, quotaDailyUsed: nil, quotaWeeklyLimit: nil, quotaWeeklyUsed: nil, errorMessage: "", rateLimitResetAt: nil),
        ]),
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )

    let failed = MonitorSnapshot(
        mode: .user,
        connected: false,
        stats: nil,
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: nil,
        message: "offline"
    )

    #expect(healthy.severity == .healthy)
    #expect(warned.severity == .warning)
    #expect(failed.severity == .error)
}

@Test func monitorSnapshotLabelsNearLimitSeparatelyFromConnectionFailure() {
    let nearLimit = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: nil,
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: SubscriptionSummary(activeCount: 1, subscriptions: [
            SubscriptionSummaryItem(id: 1, groupName: "codex", status: "active", dailyProgress: 0.966, weeklyProgress: nil, monthlyProgress: nil, expiresAt: nil, daysRemaining: 20),
        ]),
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )
    let disconnected = MonitorSnapshot(
        mode: .user,
        connected: false,
        stats: nil,
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: nil,
        message: "offline"
    )

    #expect(nearLimit.statusLabel == "Near Limit")
    #expect(disconnected.statusLabel == "Disconnected")
}

@Test func monitorSnapshotBuildsMenuBarSummaryFromDashboardStats() {
    let snapshot = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayRequests: 1119, todayActualCost: 113.3052, rpm: 3),
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )

    #expect(snapshot.menuBarSummary == "$113.31 · 1119 req · 3 RPM")
}

@Test func usageInsightsPrioritizeQuotaBalanceTrendAndModelConcentration() {
    let stats = DashboardStats(
        totalRequests: 20_000,
        totalTokens: 2_000_000,
        totalActualCost: 420,
        todayRequests: 1_200,
        todayTokens: 210_000,
        todayActualCost: 42,
        rpm: 6,
        tpm: 11_000
    )
    let currentUser = CurrentUser(
        id: 1,
        email: "user@example.com",
        username: "User",
        role: "user",
        balance: 70,
        status: "active"
    )
    let subscriptionSummary = SubscriptionSummary(activeCount: 1, subscriptions: [
        SubscriptionSummaryItem(
            id: 1,
            groupName: "Codex",
            status: "active",
            dailyProgress: 0.93,
            weeklyProgress: 0.66,
            monthlyProgress: 0.45,
            expiresAt: nil,
            daysRemaining: 18
        ),
    ])
    let trend = [
        TrendDataPoint(date: "2026-05-12", totalTokens: 100_000, actualCost: 10),
        TrendDataPoint(date: "2026-05-13", totalTokens: 110_000, actualCost: 11),
        TrendDataPoint(date: "2026-05-14", totalTokens: 120_000, actualCost: 12),
        TrendDataPoint(date: "2026-05-15", totalTokens: 130_000, actualCost: 13),
        TrendDataPoint(date: "2026-05-16", totalTokens: 140_000, actualCost: 14),
        TrendDataPoint(date: "2026-05-17", totalTokens: 150_000, actualCost: 15),
        TrendDataPoint(date: "2026-05-18", totalTokens: 270_000, actualCost: 42),
    ]
    let models = [
        ModelUsageSummary(model: "gpt-5.5", requests: 900, totalTokens: 170_000, actualCost: 36),
        ModelUsageSummary(model: "gpt-5.4", requests: 300, totalTokens: 40_000, actualCost: 6),
    ]

    let insights = UsageInsights.make(
        currentUser: currentUser,
        stats: stats,
        subscriptionSummary: subscriptionSummary,
        trend: trend,
        models: models
    )

    #expect(insights.headline == "Daily quota is at 93%.")
    #expect(insights.items.map(\.kind).contains(.quota))
    #expect(insights.items.map(\.kind).contains(.balance))
    #expect(insights.items.map(\.kind).contains(.trend))
    #expect(insights.items.map(\.kind).contains(.modelMix))
    #expect(insights.items.first?.severity == .warning)
    #expect(insights.items.contains { $0.title == "Balance runway" && $0.value == "1.7d" })
    #expect(insights.items.contains { $0.title == "Token surge" })
}

@Test func usageInsightsRespectCustomThresholds() {
    let stats = DashboardStats(todayTokens: 210_000, todayActualCost: 15, averageDurationMs: 16_000)
    let currentUser = CurrentUser(
        id: 1,
        email: "user@example.com",
        username: "User",
        role: "user",
        balance: 60,
        status: "active"
    )
    let summary = SubscriptionSummary(activeCount: 1, subscriptions: [
        SubscriptionSummaryItem(
            id: 1,
            groupName: "Team",
            status: "active",
            dailyProgress: 0.76,
            weeklyProgress: nil,
            monthlyProgress: nil,
            expiresAt: nil,
            daysRemaining: nil
        ),
    ])
    let trend = [
        TrendDataPoint(date: "2026-05-15", totalTokens: 100_000),
        TrendDataPoint(date: "2026-05-16", totalTokens: 100_000),
        TrendDataPoint(date: "2026-05-17", totalTokens: 100_000),
        TrendDataPoint(date: "2026-05-18", totalTokens: 130_000),
    ]
    let models = [
        ModelUsageSummary(model: "gpt-5.5", totalTokens: 100, actualCost: 7),
        ModelUsageSummary(model: "gpt-5.4", totalTokens: 100, actualCost: 3),
    ]
    var thresholds = InsightThresholds.defaults
    thresholds.quotaWarningProgress = 0.75
    thresholds.lowBalanceDays = 5
    thresholds.tokenSurgeRatio = 1.2
    thresholds.modelConcentrationShare = 0.65
    thresholds.latencyWarningMs = 15_000

    let insights = UsageInsights.make(
        currentUser: currentUser,
        stats: stats,
        subscriptionSummary: summary,
        trend: trend,
        models: models,
        thresholds: thresholds
    )

    #expect(insights.items.contains { $0.kind == .quota && $0.severity == .warning })
    #expect(insights.items.contains { $0.kind == .balance && $0.severity == .warning })
    #expect(insights.items.contains { $0.kind == .trend && $0.title == "Token surge" })
    #expect(insights.items.contains { $0.kind == .modelMix && $0.severity == .warning })
    #expect(insights.items.contains { $0.kind == .performance && $0.severity == .warning })
}

@Test func insightAlertPolicyReturnsHighestPriorityActionableInsight() {
    let insights = UsageInsights(headline: "Daily quota is at 93%.", items: [
        UsageInsightItem(
            kind: .trend,
            severity: .healthy,
            title: "Token trend",
            value: "steady",
            detail: "Token usage is steady."
        ),
        UsageInsightItem(
            kind: .quota,
            severity: .warning,
            title: "Daily quota",
            value: "93%",
            detail: "Daily quota is at 93%."
        ),
    ])
    let policy = InsightAlertPolicy(settings: .defaults)

    let alert = policy.nextAlert(from: insights, lastAlertedAtByFingerprint: [:], now: Date(timeIntervalSince1970: 0))

    #expect(alert?.title == "Daily quota")
    #expect(alert?.body == "Daily quota is at 93%.")
    #expect(alert?.severity == .warning)
}

@Test func insightAlertPolicySuppressesRepeatedAlertsInsideCooldown() {
    let insights = UsageInsights(headline: "Balance covers less than one day at today's spend.", items: [
        UsageInsightItem(
            kind: .balance,
            severity: .warning,
            title: "Balance runway",
            value: "0.8d",
            detail: "Balance covers less than one day at today's spend."
        ),
    ])
    let policy = InsightAlertPolicy(settings: InsightAlertSettings(isEnabled: true, minimumSeverity: .warning, cooldownMinutes: 60))
    let firstTime = Date(timeIntervalSince1970: 1_000)
    let firstAlert = policy.nextAlert(from: insights, lastAlertedAtByFingerprint: [:], now: firstTime)

    let suppressed = policy.nextAlert(
        from: insights,
        lastAlertedAtByFingerprint: [firstAlert?.fingerprint ?? "": firstTime],
        now: firstTime.addingTimeInterval(30 * 60)
    )
    let allowed = policy.nextAlert(
        from: insights,
        lastAlertedAtByFingerprint: [firstAlert?.fingerprint ?? "": firstTime],
        now: firstTime.addingTimeInterval(61 * 60)
    )

    #expect(firstAlert != nil)
    #expect(suppressed == nil)
    #expect(allowed?.fingerprint == firstAlert?.fingerprint)
}

@Test func insightAlertPolicySuppressesSameSignalWhenValueChangesInsideCooldown() {
    let firstInsights = UsageInsights(headline: "Daily quota is at 93%.", items: [
        UsageInsightItem(
            kind: .quota,
            severity: .warning,
            title: "Daily quota",
            value: "93%",
            detail: "Daily quota is at 93%."
        ),
    ])
    let updatedInsights = UsageInsights(headline: "Daily quota is at 94%.", items: [
        UsageInsightItem(
            kind: .quota,
            severity: .warning,
            title: "Daily quota",
            value: "94%",
            detail: "Daily quota is at 94%."
        ),
    ])
    let policy = InsightAlertPolicy(settings: InsightAlertSettings(isEnabled: true, minimumSeverity: .warning, cooldownMinutes: 60))
    let firstTime = Date(timeIntervalSince1970: 2_000)
    let firstAlert = policy.nextAlert(from: firstInsights, lastAlertedAtByFingerprint: [:], now: firstTime)

    let suppressed = policy.nextAlert(
        from: updatedInsights,
        lastAlertedAtByFingerprint: [firstAlert?.fingerprint ?? "": firstTime],
        now: firstTime.addingTimeInterval(15 * 60)
    )

    #expect(firstAlert?.fingerprint == "quota-Daily quota-warning")
    #expect(suppressed == nil)
}

@Test func insightAlertPolicyRespectsDisabledAndMinimumSeveritySettings() {
    let insights = UsageInsights(headline: "gpt-5.5 drives 82% of model spend.", items: [
        UsageInsightItem(
            kind: .modelMix,
            severity: .warning,
            title: "Top model",
            value: "82%",
            detail: "gpt-5.5 drives 82% of model spend."
        ),
    ])

    let disabled = InsightAlertPolicy(settings: InsightAlertSettings(isEnabled: false, minimumSeverity: .warning, cooldownMinutes: 60))
    let errorOnly = InsightAlertPolicy(settings: InsightAlertSettings(isEnabled: true, minimumSeverity: .error, cooldownMinutes: 60))

    #expect(disabled.nextAlert(from: insights, lastAlertedAtByFingerprint: [:], now: Date()) == nil)
    #expect(errorOnly.nextAlert(from: insights, lastAlertedAtByFingerprint: [:], now: Date()) == nil)
}

@Test func diagnosticReportRedactsStoredTokenValues() {
    let account = StoredAccount(
        id: "work",
        name: "Work",
        email: "das@example.com",
        baseURL: "https://sub2api.example.com",
        authToken: "secret-access-token",
        refreshToken: "secret-refresh-token"
    )
    let config = AppConfig(
        baseURL: "https://sub2api.example.com",
        authToken: "secret-access-token",
        refreshToken: "secret-refresh-token",
        refreshIntervalSeconds: 30,
        showsMenuBarText: true,
        insightAlertSettings: InsightAlertSettings(isEnabled: true, minimumSeverity: .error, cooldownMinutes: 90),
        accounts: [account],
        selectedAccountID: account.id
    )
    let snapshot = MonitorSnapshot(
        mode: .user,
        connected: true,
        currentUser: CurrentUser(
            id: 1,
            email: "das@example.com",
            username: "Das",
            role: "user",
            balance: 12.34,
            status: "active"
        ),
        stats: DashboardStats(todayRequests: 42, todayActualCost: 3.14, rpm: 2),
        trend: [
            TrendDataPoint(date: "2026-05-17", totalTokens: 100),
            TrendDataPoint(date: "2026-05-18", totalTokens: 110),
        ],
        modelDistribution: [
            ModelUsageSummary(model: "gpt-5.5", totalTokens: 100, actualCost: 3.14),
        ],
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )

    let report = DiagnosticReport.make(
        config: config,
        snapshot: snapshot,
        appVersion: "0.1.5",
        notificationAuthorization: .denied,
        osVersion: "macOS 15.0"
    )

    #expect(report.contains("Sub2API Status Bar Diagnostics"))
    #expect(report.contains("Version: 0.1.5"))
    #expect(report.contains("Access Token: present"))
    #expect(report.contains("Refresh Token: present"))
    #expect(report.contains("Insight Alerts: enabled"))
    #expect(report.contains("Insight Alert Level: error"))
    #expect(report.contains("Insight Alert Cooldown: 90m"))
    #expect(report.contains("Notification Permission: denied"))
    #expect(report.contains("Usage Insight: Balance covers about 3.9 days at today's spend."))
    #expect(report.contains("secret-access-token") == false)
    #expect(report.contains("secret-refresh-token") == false)
}

@Test func loginFormStateRequiresURLAccountAndPassword() {
    #expect(LoginFormState(baseURL: "", email: "a@example.com", password: "secret").canSubmit == false)
    #expect(LoginFormState(baseURL: "http://127.0.0.1:8080", email: "", password: "secret").canSubmit == false)
    #expect(LoginFormState(baseURL: "http://127.0.0.1:8080", email: "a@example.com", password: "").canSubmit == false)
    #expect(LoginFormState(baseURL: "http://127.0.0.1:8080", email: "a@example.com", password: "secret").canSubmit == true)
}
