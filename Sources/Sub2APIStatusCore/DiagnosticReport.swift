import Foundation

public enum DiagnosticReport {
    public static func make(
        config: AppConfig,
        snapshot: MonitorSnapshot,
        appVersion: String,
        notificationAuthorization: InsightNotificationAuthorization? = nil,
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
    ) -> String {
        let now = Date()
        let isStale = snapshot.isStale(now: now, refreshIntervalSeconds: config.refreshIntervalSeconds)
        var lines = [
            "Sub2API Status Bar Diagnostics",
            "Version: \(appVersion)",
            "OS: \(osVersion)",
            "Status: \(snapshot.statusLabel(now: now, refreshIntervalSeconds: config.refreshIntervalSeconds))",
            "Connected: \(snapshot.connected ? "yes" : "no")",
            "Data Freshness: \(isStale ? "stale" : "fresh")",
            "Base URL: \(config.baseURL)",
            "Refresh Interval: \(Int(config.refreshIntervalSeconds))s",
            "Menu Bar Text: \(config.showsMenuBarText ? "shown" : "hidden")",
            "Menu Bar Metric: \(config.menuBarMetric.rawValue)",
            "Insight Alerts: \(config.insightAlertSettings.isEnabled ? "enabled" : "disabled")",
            "Insight Alert Level: \(config.insightAlertSettings.minimumSeverity.rawValue)",
            "Insight Alert Cooldown: \(Int(config.insightAlertSettings.cooldownMinutes))m",
            "Monthly Budget: \(StatusFormatters.currency(config.insightThresholds.monthlyBudgetUSD))",
            "Spend Surge Threshold: \(Int(config.insightThresholds.spendSurgeRatio * 100))%",
            "Notification Permission: \(notificationAuthorization?.rawValue ?? "unknown")",
            "Accounts: \(config.accounts.count)",
            "Selected Account: \(config.selectedAccount?.displayName ?? "none")",
            "Access Token: \(config.authToken.isEmpty ? "missing" : "present")",
            "Refresh Token: \(config.refreshToken.isEmpty ? "missing" : "present")",
        ]

        if let stats = snapshot.stats {
            lines.append("Today Requests: \(stats.todayRequests)")
            lines.append("Today Cost: \(StatusFormatters.preciseCurrency(stats.todayActualCost))")
            lines.append("Today Tokens: \(stats.todayTokens)")
            lines.append("Today Cost per MTok: \(StatusFormatters.costPerMillionTokens(cost: stats.todayActualCost, tokens: stats.todayTokens))")
            lines.append("Total Tokens: \(stats.totalTokens)")
            lines.append("RPM: \(StatusFormatters.menuBarRate(stats.rpm))")
            lines.append("TPM: \(StatusFormatters.compactNumber(Int64(stats.tpm)))")
        }

        if let subscriptionSummary = snapshot.subscriptionSummary {
            lines.append("Active Subscriptions: \(subscriptionSummary.activeCount)")
            lines.append("Highest Quota Usage: \(StatusFormatters.percent(subscriptionSummary.highestProgress))")
            lines.append("Expiring Soon: \(subscriptionSummary.expiringSoonCount)")
        }

        if let models = snapshot.modelDistribution {
            lines.append("Visible Models: \(models.prefix(5).map(\.model).joined(separator: ", "))")
        }

        if snapshot.connected {
            let insights = UsageInsights.make(
                currentUser: snapshot.currentUser,
                stats: snapshot.stats,
                subscriptionSummary: snapshot.subscriptionSummary,
                trend: snapshot.trend,
                models: snapshot.modelDistribution,
                thresholds: config.insightThresholds
            )
            lines.append("Usage Insight: \(insights.headline)")
            for item in insights.items {
                lines.append("Insight \(item.title): \(item.value) - \(item.detail)")
            }
        }

        if let lastUpdatedAt = snapshot.lastUpdatedAt {
            lines.append("Last Updated: \(ISO8601DateFormatter().string(from: lastUpdatedAt))")
        }

        if let message = snapshot.message, !message.isEmpty {
            lines.append("Message: \(message)")
        }

        return lines.joined(separator: "\n")
    }
}
