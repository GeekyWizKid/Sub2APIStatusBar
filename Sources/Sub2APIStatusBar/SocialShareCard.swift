import AppKit
import SwiftUI
import Sub2APIStatusCore

enum SocialShareCardRenderer {
    @MainActor
    static func image(for summary: SocialShareSummary) -> NSImage? {
        let view = SocialShareCard(summary: summary)
            .frame(width: 920, height: 520)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 920, height: 520)
        renderer.scale = 2
        return renderer.nsImage
    }
}

struct SocialShareCard: View {
    let summary: SocialShareSummary

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.14, blue: 0.16),
                    Color(red: 0.04, green: 0.05, blue: 0.07),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(summary.title)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(summary.tagline)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.68))
                    }

                    Spacer()

                    Text("Sub2API Status Bar")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.86))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }

                HStack(alignment: .lastTextBaseline, spacing: 14) {
                    Text(summary.primaryMetric)
                        .font(.system(size: 90, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(summary.primaryLabel.uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.54, green: 0.92, blue: 0.76))
                        .lineLimit(2)
                }

                HStack(spacing: 14) {
                    shareMetric(title: "Spend", value: summary.spendText, tint: Color(red: 0.54, green: 0.92, blue: 0.76))
                    shareMetric(title: "Requests", value: summary.requestsText, tint: Color(red: 0.44, green: 0.72, blue: 1.0))
                    shareMetric(title: "Cost / MTok", value: summary.unitCostText, tint: Color(red: 0.96, green: 0.72, blue: 0.33))
                }

                VStack(alignment: .leading, spacing: 11) {
                    detailRow(icon: "sparkles", label: "Top model", value: summary.topModelText)
                    detailRow(icon: "gauge", label: "Quota", value: summary.quotaText)
                    detailRow(icon: "chart.line.uptrend.xyaxis", label: "Trend", value: summary.trendText)
                }

                Spacer(minLength: 0)

                HStack {
                    Text(summary.generatedText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Spacer()
                    Text("#AIUsage  #BuildInPublic")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.54, green: 0.92, blue: 0.76))
                }
            }
            .padding(34)
        }
    }

    private func shareMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.54))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            SafeSystemImage(systemName: icon, fallbackName: "circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 0.54, green: 0.92, blue: 0.76))
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.56))
                .frame(width: 82, alignment: .leading)
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
    }
}
