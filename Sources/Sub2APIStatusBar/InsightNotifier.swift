import Foundation
import Sub2APIStatusCore
import UserNotifications

@MainActor
final class InsightNotifier {
    private var lastAlertedAtByFingerprint: [String: Date] = [:]

    func handle(insights: UsageInsights, settings: InsightAlertSettings) {
        let policy = InsightAlertPolicy(settings: settings)
        guard let alert = policy.nextAlert(
            from: insights,
            lastAlertedAtByFingerprint: lastAlertedAtByFingerprint,
            now: Date()
        ) else {
            return
        }

        Task {
            if await deliver(alert) {
                lastAlertedAtByFingerprint[alert.fingerprint] = Date()
            }
        }
    }

    func resetCooldowns() {
        lastAlertedAtByFingerprint.removeAll()
    }

    private func deliver(_ alert: InsightAlert) async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus != .denied else {
                return false
            }

            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else {
                    return false
                }
            }

            let content = UNMutableNotificationContent()
            content.title = "Sub2API \(alert.title)"
            content.body = alert.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "sub2api-insight-\(alert.fingerprint)",
                content: content,
                trigger: nil
            )
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
