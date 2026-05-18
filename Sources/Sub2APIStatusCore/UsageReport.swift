import Foundation

public enum UsageReport {
    public static func make(
        config: AppConfig,
        snapshot: MonitorSnapshot,
        now: Date = Date()
    ) -> String {
        var lines = [
            "Sub2API Usage Report",
            "Generated: \(ISO8601DateFormatter().string(from: now))",
            "Status: \(snapshot.statusLabel(now: now, refreshIntervalSeconds: config.refreshIntervalSeconds))",
            "Account: \(accountText(snapshot.currentUser))",
        ]

        if let lastUpdatedAt = snapshot.lastUpdatedAt {
            lines.append("Last Updated: \(ISO8601DateFormatter().string(from: lastUpdatedAt))")
        }

        if let balance = snapshot.currentUser?.balance {
            lines.append("Balance: \(StatusFormatters.currency(balance))")
        }

        if let stats = snapshot.stats {
            lines.append("Today Spend: \(StatusFormatters.preciseCurrency(stats.todayActualCost))")
            lines.append("Today Requests: \(StatusFormatters.menuBarCount(stats.todayRequests))")
            lines.append("Today Tokens: \(StatusFormatters.compactNumber(stats.todayTokens))")
            lines.append("Token Mix: \(tokenMix(stats))")
            lines.append("Cost / MTok: \(StatusFormatters.costPerMillionTokens(cost: stats.todayActualCost, tokens: stats.todayTokens))")
            lines.append("Throughput: \(StatusFormatters.menuBarRate(stats.rpm)) RPM / \(StatusFormatters.compactNumber(Int64(stats.tpm))) TPM")
            lines.append("Average Response: \(latencyText(milliseconds: stats.averageDurationMs))")
            lines.append("Lifetime Spend: \(StatusFormatters.preciseCurrency(stats.totalActualCost))")
            lines.append("Lifetime Tokens: \(StatusFormatters.compactNumber(stats.totalTokens))")
        }

        if let subscriptionSummary = snapshot.subscriptionSummary {
            lines.append("Subscriptions: \(subscriptionSummary.activeCount) active")
            if let quota = topQuota(subscriptionSummary) {
                let resetText = quota.resetInSeconds.map { ", resets in \(StatusFormatters.duration(seconds: $0))" } ?? ""
                lines.append("\(quota.name): \(StatusFormatters.percent(quota.progress))\(resetText)")
            }
        }

        if let latestTrend = snapshot.trend?.last {
            lines.append(
                "Trend \(latestTrend.date): \(StatusFormatters.menuBarCount(latestTrend.requests)) requests, \(StatusFormatters.compactNumber(latestTrend.totalTokens)) tokens, \(StatusFormatters.preciseCurrency(latestTrend.actualCost))"
            )
        }

        if let modelText = topModelsText(snapshot.modelDistribution) {
            lines.append("Top Models: \(modelText)")
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
            lines.append("Insight: \(insights.headline)")
            for item in insights.items {
                lines.append("- \(item.title): \(item.value) - \(item.detail)")
            }
        }

        if let message = snapshot.message, !message.isEmpty {
            lines.append("Message: \(message)")
        }

        return lines.joined(separator: "\n")
    }

    private static func accountText(_ user: CurrentUser?) -> String {
        guard let user else {
            return "Unknown"
        }

        let displayName = if let username = user.username, !username.isEmpty {
            username
        } else {
            user.email
        }

        if user.email.isEmpty || displayName == user.email {
            return displayName
        }
        return "\(displayName) <\(user.email)>"
    }

    private static func tokenMix(_ stats: DashboardStats) -> String {
        [
            "Input \(StatusFormatters.compactNumber(stats.todayInputTokens))",
            "Output \(StatusFormatters.compactNumber(stats.todayOutputTokens))",
            "Cache Read \(StatusFormatters.compactNumber(stats.todayCacheReadTokens))",
        ].joined(separator: " / ")
    }

    private static func latencyText(milliseconds: Double) -> String {
        if milliseconds >= 1_000 {
            return String(format: "%.2fs", milliseconds / 1_000)
        }
        return "\(Int(milliseconds))ms"
    }

    private static func topQuota(_ summary: SubscriptionSummary) -> (name: String, progress: Double, resetInSeconds: Double?)? {
        summary.subscriptions
            .flatMap { item in
                [
                    (name: "\(item.groupName) daily quota", progress: item.dailyProgress, resetInSeconds: item.dailyResetInSeconds),
                    (name: "\(item.groupName) weekly quota", progress: item.weeklyProgress, resetInSeconds: item.weeklyResetInSeconds),
                    (name: "\(item.groupName) monthly quota", progress: item.monthlyProgress, resetInSeconds: item.monthlyResetInSeconds),
                ]
            }
            .compactMap { candidate -> (name: String, progress: Double, resetInSeconds: Double?)? in
                guard let progress = candidate.progress else {
                    return nil
                }
                return (candidate.name, min(max(progress, 0), 1), candidate.resetInSeconds)
            }
            .max(by: { $0.progress < $1.progress })
    }

    private static func topModelsText(_ models: [ModelUsageSummary]?) -> String? {
        guard let models, !models.isEmpty else {
            return nil
        }

        return models
            .prefix(3)
            .map { "\($0.model) \(StatusFormatters.preciseCurrency($0.actualCost)) (\(StatusFormatters.compactNumber($0.totalTokens)) tokens)" }
            .joined(separator: ", ")
    }
}
