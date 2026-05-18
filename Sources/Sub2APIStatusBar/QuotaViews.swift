import SwiftUI
import Sub2APIStatusCore

struct SubscriptionQuotaCard: View {
    let item: SubscriptionSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(item.status == "active" ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(item.groupName)
                    .font(.headline)
                Spacer()
                Text(item.status == "active" ? "Active" : item.status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(item.status == "active" ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((item.status == "active" ? Color.green : Color.secondary).opacity(0.14), in: Capsule())
            }

            quotaSummary

            ForEach(quotaWindows, id: \.title) { window in
                QuotaProgressRow(window: window)
            }
        }
    }

    private var quotaWindows: [QuotaWindowDisplay] {
        [
            QuotaWindowDisplay(
                title: "Daily",
                used: item.dailyUsedUSD,
                limit: item.dailyLimitUSD,
                progress: item.dailyProgress,
                resetInSeconds: item.dailyResetInSeconds
            ),
            QuotaWindowDisplay(
                title: "Weekly",
                used: item.weeklyUsedUSD,
                limit: item.weeklyLimitUSD,
                progress: item.weeklyProgress,
                resetInSeconds: item.weeklyResetInSeconds
            ),
            QuotaWindowDisplay(
                title: "Monthly",
                used: item.monthlyUsedUSD,
                limit: item.monthlyLimitUSD,
                progress: item.monthlyProgress,
                resetInSeconds: item.monthlyResetInSeconds
            ),
        ]
    }

    private var quotaSummary: some View {
        HStack(spacing: 8) {
            Label(bestWindow.percentText, systemImage: "gauge.with.dots.needle.67percent")
                .foregroundStyle(tint(for: bestWindow.severity))
            Text(bestWindow.remainingText)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            if let days = item.daysRemaining {
                Label("\(days)d left", systemImage: "calendar.badge.clock")
                    .foregroundStyle(days <= 3 ? .orange : .secondary)
            }
        }
        .font(.caption.weight(.medium))
    }

    private var bestWindow: QuotaWindowDisplay {
        quotaWindows.max { $0.normalizedProgress < $1.normalizedProgress } ?? quotaWindows[0]
    }

    private func tint(for severity: MonitorSeverity) -> Color {
        switch severity {
        case .healthy:
            .green
        case .warning:
            .orange
        case .error:
            .red
        }
    }
}

struct QuotaProgressRow: View {
    let window: QuotaWindowDisplay

    private var tint: Color {
        switch window.severity {
        case .healthy:
            .green
        case .warning:
            .orange
        case .error:
            .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(window.title)
                    .font(.callout.weight(.semibold))
                Spacer()
                Text(window.percentText)
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tint)
                Text(window.amountText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            ProgressView(value: window.normalizedProgress)
                .tint(tint)

            HStack {
                Text(window.remainingText)
                Spacer()
                if let resetText = window.resetText {
                    Text(resetText)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(window.title) quota \(window.percentText), \(window.remainingText)")
        }
    }
}
