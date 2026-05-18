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

            if let days = item.daysRemaining {
                HStack {
                    Text("Expires")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Remaining \(days)d")
                }
                .font(.caption)
            }

            QuotaProgressRow(
                title: "Daily",
                used: item.dailyUsedUSD,
                limit: item.dailyLimitUSD,
                progress: item.dailyProgress,
                resetInSeconds: item.dailyResetInSeconds
            )
            QuotaProgressRow(
                title: "Weekly",
                used: item.weeklyUsedUSD,
                limit: item.weeklyLimitUSD,
                progress: item.weeklyProgress,
                resetInSeconds: item.weeklyResetInSeconds
            )
            QuotaProgressRow(
                title: "Monthly",
                used: item.monthlyUsedUSD,
                limit: item.monthlyLimitUSD,
                progress: item.monthlyProgress,
                resetInSeconds: item.monthlyResetInSeconds
            )
        }
    }
}

struct QuotaProgressRow: View {
    let title: String
    let used: Double?
    let limit: Double?
    let progress: Double?
    let resetInSeconds: Double?

    private var normalizedProgress: Double {
        min(max(progress ?? 0, 0), 1)
    }

    private var tint: Color {
        normalizedProgress >= 0.95 ? .red : .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.callout.weight(.semibold))
                Spacer()
                Text(amountText)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            ProgressView(value: normalizedProgress)
                .tint(tint)

            if let resetInSeconds {
                Text("\(StatusFormatters.duration(seconds: resetInSeconds)) until reset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var amountText: String {
        guard let used, let limit else {
            return "--"
        }
        return "\(StatusFormatters.currency(used)) / \(StatusFormatters.currency(limit))"
    }
}
