import AppKit
import SwiftUI
import Sub2APIStatusCore

struct MetricItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String?
    let systemImage: String?
    let tint: Color

    init(title: String, value: String, caption: String? = nil, systemImage: String? = nil, tint: Color = .accentColor) {
        self.title = title
        self.value = value
        self.caption = caption
        self.systemImage = systemImage
        self.tint = tint
    }
}

struct UserAccountCard: View {
    let user: CurrentUser

    private var displayName: String {
        guard let username = user.username, !username.isEmpty else {
            return user.email
        }
        return username
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            if let status = user.status, !status.isEmpty {
                Text(status.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(status.lowercased() == "active" ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((status.lowercased() == "active" ? Color.green : Color.secondary).opacity(0.14), in: Capsule())
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MetricGrid: View {
    let items: [MetricItem]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(items) { item in
                HStack(spacing: 10) {
                    if let systemImage = item.systemImage {
                        SafeSystemImage(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(item.tint)
                            .frame(width: 32, height: 32)
                            .background(item.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.value)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if let caption = item.caption {
                            Text(caption)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct SafeSystemImage: View {
    let systemName: String
    var fallbackName = "circle.grid.3x3.fill"

    var body: some View {
        if let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: fallbackName, accessibilityDescription: nil) {
            Image(nsImage: image)
                .renderingMode(.template)
        } else {
            Image(systemName: "questionmark.circle")
        }
    }
}

struct UsageInsightsView: View {
    let insights: UsageInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Usage Insights")
                    .font(.headline)
                Spacer()
                Text(insights.headline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(insights.items) { item in
                    HStack(spacing: 9) {
                        SafeSystemImage(systemName: iconName(for: item.kind))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(color(for: item.severity))
                            .frame(width: 28, height: 28)
                            .background(color(for: item.severity).opacity(0.14), in: RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text(item.value)
                                .font(.callout.weight(.semibold).monospacedDigit())
                                .lineLimit(1)
                            Text(item.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                    .padding(9)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func iconName(for kind: UsageInsightKind) -> String {
        switch kind {
        case .quota:
            "gauge.with.dots.needle.67percent"
        case .balance:
            "banknote"
        case .trend:
            "chart.line.uptrend.xyaxis"
        case .modelMix:
            "square.stack.3d.up"
        case .performance:
            "speedometer"
        }
    }

    private func color(for severity: MonitorSeverity) -> Color {
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
