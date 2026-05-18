import Foundation

public enum UsageInsightKind: String, Equatable, Sendable {
    case quota
    case balance
    case spend
    case trend
    case modelMix
    case performance

    public var sortRank: Int {
        switch self {
        case .quota:
            0
        case .balance:
            1
        case .spend:
            2
        case .trend:
            3
        case .modelMix:
            4
        case .performance:
            5
        }
    }
}

public struct UsageInsightItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: UsageInsightKind
    public let severity: MonitorSeverity
    public let title: String
    public let value: String
    public let detail: String

    public init(
        kind: UsageInsightKind,
        severity: MonitorSeverity,
        title: String,
        value: String,
        detail: String
    ) {
        self.id = "\(kind.rawValue)-\(title)-\(value)-\(detail)"
        self.kind = kind
        self.severity = severity
        self.title = title
        self.value = value
        self.detail = detail
    }
}

public struct UsageInsights: Equatable, Sendable {
    public let headline: String
    public let items: [UsageInsightItem]

    public init(headline: String, items: [UsageInsightItem]) {
        self.headline = headline
        self.items = items
    }

    public static func make(
        currentUser: CurrentUser?,
        stats: DashboardStats?,
        subscriptionSummary: SubscriptionSummary?,
        trend: [TrendDataPoint]?,
        models: [ModelUsageSummary]?,
        thresholds: InsightThresholds = .defaults
    ) -> UsageInsights {
        var thresholds = thresholds
        thresholds.normalize()
        var items: [UsageInsightItem] = []

        if let quota = quotaInsight(subscriptionSummary, thresholds: thresholds) {
            items.append(quota)
        }

        if let balance = balanceInsight(currentUser: currentUser, stats: stats, thresholds: thresholds) {
            items.append(balance)
        }

        if let spend = spendInsight(trend, thresholds: thresholds) {
            items.append(spend)
        }

        if let trend = trendInsight(trend, thresholds: thresholds) {
            items.append(trend)
        }

        if let modelMix = modelMixInsight(models, thresholds: thresholds) {
            items.append(modelMix)
        }

        if let performance = performanceInsight(stats, thresholds: thresholds) {
            items.append(performance)
        }

        items.sort { lhs, rhs in
            if lhs.severity.sortRank != rhs.severity.sortRank {
                return lhs.severity.sortRank > rhs.severity.sortRank
            }
            return lhs.kind.sortRank < rhs.kind.sortRank
        }

        let headline = items.first?.detail ?? "Usage is steady."
        return UsageInsights(headline: headline, items: Array(items.prefix(5)))
    }

    private static func quotaInsight(_ summary: SubscriptionSummary?, thresholds: InsightThresholds) -> UsageInsightItem? {
        guard let summary else {
            return nil
        }

        let candidates = summary.subscriptions.flatMap { item in
            [
                (groupName: item.groupName, label: "daily", progress: item.dailyProgress, resetInSeconds: item.dailyResetInSeconds),
                (groupName: item.groupName, label: "weekly", progress: item.weeklyProgress, resetInSeconds: item.weeklyResetInSeconds),
                (groupName: item.groupName, label: "monthly", progress: item.monthlyProgress, resetInSeconds: item.monthlyResetInSeconds),
            ]
        }

        guard let peak = candidates
            .compactMap({ candidate -> (groupName: String, label: String, progress: Double, resetInSeconds: Double?)? in
                guard let progress = candidate.progress else {
                    return nil
                }
                return (candidate.groupName, candidate.label, min(max(progress, 0), 1), candidate.resetInSeconds)
            })
            .max(by: { $0.progress < $1.progress }) else {
            return nil
        }

        let severity: MonitorSeverity = if peak.progress >= thresholds.quotaCriticalProgress {
            .error
        } else if peak.progress >= thresholds.quotaWarningProgress {
            .warning
        } else {
            .healthy
        }

        let title = "\(peak.groupName) \(peak.label) quota"
        let resetText = peak.resetInSeconds.map { " and resets in \(StatusFormatters.duration(seconds: $0))" } ?? ""
        return UsageInsightItem(
            kind: .quota,
            severity: severity,
            title: title,
            value: StatusFormatters.percent(peak.progress),
            detail: "\(title) is at \(StatusFormatters.percent(peak.progress))\(resetText)."
        )
    }

    private static func balanceInsight(currentUser: CurrentUser?, stats: DashboardStats?, thresholds: InsightThresholds) -> UsageInsightItem? {
        guard let balance = currentUser?.balance, balance > 0, let stats, stats.todayActualCost > 0 else {
            return nil
        }

        let days = balance / stats.todayActualCost
        let severity: MonitorSeverity = if days < 1 {
            .error
        } else if days < thresholds.lowBalanceDays {
            .warning
        } else {
            .healthy
        }

        return UsageInsightItem(
            kind: .balance,
            severity: severity,
            title: "Balance runway",
            value: String(format: "%.1fd", days),
            detail: "Balance covers about \(String(format: "%.1f", days)) days at today's spend."
        )
    }

    private static func trendInsight(_ trend: [TrendDataPoint]?, thresholds: InsightThresholds) -> UsageInsightItem? {
        guard let trend, trend.count >= 4, let latest = trend.last else {
            return nil
        }

        let previous = trend.dropLast().suffix(6)
        let average = previous.map { Double($0.totalTokens) }.reduce(0, +) / Double(previous.count)
        guard average > 0 else {
            return nil
        }

        let ratio = Double(latest.totalTokens) / average
        let dipRatio = max(0, 2 - thresholds.tokenSurgeRatio)
        guard ratio >= thresholds.tokenSurgeRatio || ratio <= dipRatio else {
            return UsageInsightItem(
                kind: .trend,
                severity: .healthy,
                title: "Token trend",
                value: "steady",
                detail: "Token usage is close to the recent average."
            )
        }

        let isSpike = ratio > 1
        let change = abs(ratio - 1)
        return UsageInsightItem(
            kind: .trend,
            severity: isSpike ? .warning : .healthy,
            title: isSpike ? "Token surge" : "Token dip",
            value: StatusFormatters.percent(change),
            detail: isSpike
                ? "Today's tokens are \(StatusFormatters.percent(change)) above the recent average."
                : "Today's tokens are \(StatusFormatters.percent(change)) below the recent average."
        )
    }

    private static func spendInsight(_ trend: [TrendDataPoint]?, thresholds: InsightThresholds) -> UsageInsightItem? {
        guard let trend, trend.count >= 4, let latest = trend.last else {
            return nil
        }

        let previous = trend.dropLast().suffix(6)
        let average = previous.map(\.actualCost).reduce(0, +) / Double(previous.count)
        guard average > 0 else {
            return nil
        }

        let ratio = latest.actualCost / average
        guard ratio >= thresholds.spendSurgeRatio else {
            return nil
        }

        let change = ratio - 1
        return UsageInsightItem(
            kind: .spend,
            severity: .warning,
            title: "Spend surge",
            value: StatusFormatters.percent(change),
            detail: "Today's spend is \(StatusFormatters.percent(change)) above the recent average."
        )
    }

    private static func modelMixInsight(_ models: [ModelUsageSummary]?, thresholds: InsightThresholds) -> UsageInsightItem? {
        guard let models, models.count > 1 else {
            return nil
        }

        let totalCost = models.map(\.actualCost).reduce(0, +)
        guard totalCost > 0, let top = models.max(by: { $0.actualCost < $1.actualCost }) else {
            return nil
        }

        let share = top.actualCost / totalCost
        let severity: MonitorSeverity = share >= thresholds.modelConcentrationShare ? .warning : .healthy
        return UsageInsightItem(
            kind: .modelMix,
            severity: severity,
            title: "Top model",
            value: StatusFormatters.percent(share),
            detail: "\(top.model) drives \(StatusFormatters.percent(share)) of model spend."
        )
    }

    private static func performanceInsight(_ stats: DashboardStats?, thresholds: InsightThresholds) -> UsageInsightItem? {
        guard let stats else {
            return nil
        }

        if stats.averageDurationMs >= thresholds.latencyWarningMs {
            return UsageInsightItem(
                kind: .performance,
                severity: .warning,
                title: "Latency",
                value: String(format: "%.1fs", stats.averageDurationMs / 1_000),
                detail: "Average response time is elevated."
            )
        }

        return nil
    }
}
