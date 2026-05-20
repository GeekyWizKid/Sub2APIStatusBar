import Foundation

public struct SocialShareSummary: Equatable, Sendable {
    public let title: String
    public let tagline: String
    public let personaText: String
    public let punchlineText: String
    public let privacyText: String
    public let primaryMetric: String
    public let primaryLabel: String
    public let spendText: String
    public let requestsText: String
    public let topModelText: String
    public let unitCostText: String
    public let quotaText: String
    public let trendText: String
    public let skylineValues: [Double]
    public let flexBadges: [String]
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
        let skyline = skylineValues(snapshot.trend, fallbackTokens: stats?.todayTokens ?? 0)
        let generated = generatedText(now)

        let todayTokens = stats?.todayTokens ?? 0
        let tokens = StatusFormatters.compactNumber(todayTokens)
        let spend = StatusFormatters.currency(stats?.todayActualCost ?? 0)
        let requests = StatusFormatters.menuBarCount(stats?.todayRequests ?? 0)
        let persona = "Build Log"
        let punchline = punchlineText(tokens: tokens, todayTokens: todayTokens)
        let privacy = "No prompts. No keys."
        let badges = [
            spend,
            topModelBadgeText(snapshot.modelDistribution),
            quotaBadgeText(snapshot.subscriptionSummary),
        ]

        let title = todayTokens > 0
            ? "\(tokens) AI tokens today"
            : "My AI usage receipt"
        let tagline = "A public-safe AI work counter."

        let lines = [
            title,
            persona,
            punchline,
            "\(spend) spend | \(requests) requests | \(unitCost)",
            "Top model: \(topModel)",
            "Quota: \(quota)",
            "Trend: \(trend)",
            privacy,
            "Made visible by Sub2API Status Bar.",
            "#AIUsage #BuildInPublic",
        ]

        return SocialShareSummary(
            title: title,
            tagline: tagline,
            personaText: persona,
            punchlineText: punchline,
            privacyText: privacy,
            primaryMetric: tokens,
            primaryLabel: "AI tokens today",
            spendText: spend,
            requestsText: requests,
            topModelText: topModel,
            unitCostText: unitCost,
            quotaText: quota,
            trendText: trend,
            skylineValues: skyline,
            flexBadges: badges,
            generatedText: generated,
            shareText: lines.joined(separator: "\n")
        )
    }

    private static func punchlineText(tokens: String, todayTokens: Int64) -> String {
        guard todayTokens > 0 else {
            return "The dashboard is ready for the next run."
        }
        return "The AI work counter for today."
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

    private static func quotaBadgeText(_ summary: SubscriptionSummary?) -> String {
        guard let quota = topQuota(summary) else {
            return "no quota pressure"
        }
        return "\(StatusFormatters.percent(quota.progress)) quota"
    }

    private static func topModelBadgeText(_ models: [ModelUsageSummary]?) -> String {
        guard let models, let top = models.max(by: { $0.actualCost < $1.actualCost }) else {
            return "no model data"
        }
        return top.model
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

    private static func skylineValues(_ trend: [TrendDataPoint]?, fallbackTokens: Int64) -> [Double] {
        let values = trend?.map(\.totalTokens).filter { $0 > 0 } ?? []
        if values.isEmpty {
            return fallbackTokens > 0 ? [1] : []
        }

        let maximum = Double(values.max() ?? 1)
        return values.map { value in
            let normalized = Double(value) / maximum
            return (normalized * 100).rounded() / 100
        }
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
