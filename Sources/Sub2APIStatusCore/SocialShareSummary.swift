import Foundation

public struct SocialShareSummary: Equatable, Sendable {
    public let title: String
    public let tagline: String
    public let primaryMetric: String
    public let primaryLabel: String
    public let spendText: String
    public let requestsText: String
    public let topModelText: String
    public let unitCostText: String
    public let quotaText: String
    public let trendText: String
    public let generatedText: String
    public let shareText: String

    public static func make(
        config: AppConfig,
        snapshot: MonitorSnapshot,
        now: Date = Date()
    ) -> SocialShareSummary {
        let stats = snapshot.stats
        let topModel = topModelText(snapshot.modelDistribution)
        let quota = topQuotaText(snapshot.subscriptionSummary)
        let trend = trendText(snapshot.trend)
        let unitCost = StatusFormatters.costPerMillionTokens(
            cost: stats?.todayActualCost ?? 0,
            tokens: stats?.todayTokens ?? 0
        )
        let generated = generatedText(now)

        let tokens = StatusFormatters.compactNumber(stats?.todayTokens ?? 0)
        let spend = StatusFormatters.currency(stats?.todayActualCost ?? 0)
        let requests = StatusFormatters.menuBarCount(stats?.todayRequests ?? 0)

        let lines = [
            "My Sub2API day",
            "Token flex, with receipts.",
            "\(tokens) tokens | \(spend) | \(requests) requests",
            "Top model: \(topModel)",
            "Cost/MTok: \(unitCost)",
            "Quota: \(quota)",
            "Trend: \(trend)",
            "Made visible by Sub2API Status Bar",
            "#AIUsage #BuildInPublic",
        ]

        return SocialShareSummary(
            title: "My Sub2API day",
            tagline: "Token flex, with receipts.",
            primaryMetric: tokens,
            primaryLabel: "tokens today",
            spendText: spend,
            requestsText: requests,
            topModelText: topModel,
            unitCostText: unitCost,
            quotaText: quota,
            trendText: trend,
            generatedText: generated,
            shareText: lines.joined(separator: "\n")
        )
    }

    private static func topModelText(_ models: [ModelUsageSummary]?) -> String {
        guard let models, let top = models.max(by: { $0.actualCost < $1.actualCost }) else {
            return "No model data yet"
        }

        let totalCost = models.map(\.actualCost).reduce(0, +)
        let costShare = totalCost > 0 ? top.actualCost / totalCost : 0
        return "\(top.model) (\(StatusFormatters.percent(costShare)) cost)"
    }

    private static func topQuotaText(_ summary: SubscriptionSummary?) -> String {
        guard let quota = topQuota(summary) else {
            return "No quota pressure"
        }

        let resetText = quota.resetInSeconds.map { ", resets in \(StatusFormatters.duration(seconds: $0))" } ?? ""
        return "\(quota.name) \(StatusFormatters.percent(quota.progress))\(resetText)"
    }

    private static func topQuota(_ summary: SubscriptionSummary?) -> (name: String, progress: Double, resetInSeconds: Double?)? {
        summary?.subscriptions
            .flatMap { item in
                [
                    (name: "\(item.groupName) daily", progress: item.dailyProgress, resetInSeconds: item.dailyResetInSeconds),
                    (name: "\(item.groupName) weekly", progress: item.weeklyProgress, resetInSeconds: item.weeklyResetInSeconds),
                    (name: "\(item.groupName) monthly", progress: item.monthlyProgress, resetInSeconds: item.monthlyResetInSeconds),
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

    private static func trendText(_ trend: [TrendDataPoint]?) -> String {
        guard let trend, trend.count > 1, let latest = trend.last else {
            return "Collecting baseline"
        }

        let previous = trend.dropLast()
        let average = previous.map(\.totalTokens).reduce(0, +) / Int64(max(previous.count, 1))
        guard average > 0 else {
            return "Collecting baseline"
        }

        let delta = (Double(latest.totalTokens) - Double(average)) / Double(average)
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(percentText(abs(delta))) vs \(previous.count)-day avg"
    }

    private static func percentText(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    private static func generatedText(_ now: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: now)
    }
}
