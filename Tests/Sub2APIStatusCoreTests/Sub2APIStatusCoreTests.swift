import Foundation
import Testing
@testable import Sub2APIStatusCore

final class MemoryTokenStore: TokenStore, @unchecked Sendable {
    var tokens = StoredAuthTokens()
    var saves: [StoredAuthTokens] = []

    func loadTokens() -> StoredAuthTokens {
        tokens
    }

    func saveTokens(_ tokens: StoredAuthTokens) throws {
        self.tokens = tokens
        saves.append(tokens)
    }
}

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

@Test func configStoreSavesTokensOutsideConfigJSON() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let tokenStore = MemoryTokenStore()
    let store = ConfigStore(configURL: configURL, tokenStore: tokenStore)
    let config = AppConfig(
        baseURL: "http://127.0.0.1:8080",
        authToken: "access-token",
        refreshToken: "refresh-token",
        showsMenuBarText: true
    )

    try store.save(config)

    let rawJSON = try String(contentsOf: configURL, encoding: .utf8)
    #expect(!rawJSON.contains("access-token"))
    #expect(!rawJSON.contains("refresh-token"))
    #expect(!rawJSON.contains("authToken"))
    #expect(!rawJSON.contains("refreshToken"))
    #expect(tokenStore.tokens.authToken == "access-token")
    #expect(tokenStore.tokens.refreshToken == "refresh-token")
    #expect(store.load().authToken == "access-token")
}

@Test func configStoreMigratesLegacyJSONTokensOutOfConfigFile() throws {
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
    let tokenStore = MemoryTokenStore()
    let store = ConfigStore(configURL: configURL, tokenStore: tokenStore)

    let loaded = store.load()

    #expect(loaded.authToken == "legacy-access")
    #expect(loaded.refreshToken == "legacy-refresh")
    #expect(tokenStore.tokens.authToken == "legacy-access")
    #expect(tokenStore.tokens.refreshToken == "legacy-refresh")

    let migratedJSON = try String(contentsOf: configURL, encoding: .utf8)
    #expect(!migratedJSON.contains("legacy-access"))
    #expect(!migratedJSON.contains("legacy-refresh"))
    #expect(!migratedJSON.contains("authToken"))
    #expect(!migratedJSON.contains("refreshToken"))
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

@Test func loginFormStateRequiresURLAccountAndPassword() {
    #expect(LoginFormState(baseURL: "", email: "a@example.com", password: "secret").canSubmit == false)
    #expect(LoginFormState(baseURL: "http://127.0.0.1:8080", email: "", password: "secret").canSubmit == false)
    #expect(LoginFormState(baseURL: "http://127.0.0.1:8080", email: "a@example.com", password: "").canSubmit == false)
    #expect(LoginFormState(baseURL: "http://127.0.0.1:8080", email: "a@example.com", password: "secret").canSubmit == true)
}
