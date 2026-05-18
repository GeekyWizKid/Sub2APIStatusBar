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

public enum InsightNotificationAuthorization: String, Equatable, Sendable {
    case authorized
    case denied
    case notDetermined
}

public enum InsightNotificationPermissionAction: Equatable, Sendable {
    case requestPermission
    case openSystemSettings
}

public struct InsightNotificationPermissionSummary: Equatable, Sendable {
    public let title: String
    public let detail: String
    public let action: InsightNotificationPermissionAction?

    public init(
        title: String,
        detail: String,
        action: InsightNotificationPermissionAction?
    ) {
        self.title = title
        self.detail = detail
        self.action = action
    }

    public static func make(
        settings: InsightAlertSettings,
        authorization: InsightNotificationAuthorization
    ) -> InsightNotificationPermissionSummary {
        guard settings.isEnabled else {
            return InsightNotificationPermissionSummary(
                title: "Alerts off",
                detail: "Turn on insight alerts to receive local notifications.",
                action: nil
            )
        }

        switch authorization {
        case .authorized:
            return InsightNotificationPermissionSummary(
                title: "Notifications ready",
                detail: "macOS alerts can be delivered for \(settings.minimumSeverity.rawValue) insights.",
                action: nil
            )
        case .notDetermined:
            return InsightNotificationPermissionSummary(
                title: "Permission needed",
                detail: "Allow notifications so Sub2API can warn you when usage needs attention.",
                action: .requestPermission
            )
        case .denied:
            return InsightNotificationPermissionSummary(
                title: "Notifications blocked",
                detail: "Open macOS notification settings and allow Sub2API alerts.",
                action: .openSystemSettings
            )
        }
    }
}
