import Foundation

public struct InsightAlert: Equatable, Sendable {
    public let fingerprint: String
    public let title: String
    public let body: String
    public let severity: MonitorSeverity

    public init(
        fingerprint: String,
        title: String,
        body: String,
        severity: MonitorSeverity
    ) {
        self.fingerprint = fingerprint
        self.title = title
        self.body = body
        self.severity = severity
    }
}

public struct InsightAlertPolicy: Equatable, Sendable {
    public var settings: InsightAlertSettings

    public init(settings: InsightAlertSettings) {
        self.settings = settings
        self.settings.normalize()
    }

    public func nextAlert(
        from insights: UsageInsights,
        lastAlertedAtByFingerprint: [String: Date],
        now: Date
    ) -> InsightAlert? {
        guard settings.isEnabled else {
            return nil
        }

        return insights.items
            .filter { item in item.severity.sortRank >= settings.minimumSeverity.sortRank }
            .compactMap { item -> InsightAlert? in
                let fingerprint = "\(item.kind.rawValue)-\(item.title)-\(item.severity.rawValue)"
                if let lastAlertedAt = lastAlertedAtByFingerprint[fingerprint],
                   now.timeIntervalSince(lastAlertedAt) < settings.cooldownMinutes * 60 {
                    return nil
                }

                return InsightAlert(
                    fingerprint: fingerprint,
                    title: item.title,
                    body: item.detail,
                    severity: item.severity
                )
            }
            .first
    }
}
