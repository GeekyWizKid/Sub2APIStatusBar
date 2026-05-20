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
    private let mint = Color(red: 0.52, green: 0.96, blue: 0.78)
    private let blue = Color(red: 0.34, green: 0.66, blue: 1.0)
    private let amber = Color(red: 1.0, green: 0.70, blue: 0.28)

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayer

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    HStack(spacing: 9) {
                        SafeSystemImage(systemName: "chart.bar.doc.horizontal", fallbackName: "sparkles")
                            .font(.system(size: 14, weight: .black))
                        Text("PUBLIC BUILD RECEIPT")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 0.03, green: 0.07, blue: 0.07))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(mint, in: RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Text("Sub2API Status Bar")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.86))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }

                HStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I shipped")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        HStack(alignment: .lastTextBaseline, spacing: 14) {
                            Text(summary.primaryMetric)
                                .font(.system(size: 92, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(summary.primaryLabel.uppercased())
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(mint)
                                .lineLimit(2)
                        }

                        Text(summary.tagline)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("TODAY'S RECEIPT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                        receiptMetric(title: "Spend", value: summary.spendText, tint: mint)
                        receiptMetric(title: "Requests", value: summary.requestsText, tint: blue)
                        receiptMetric(title: "Cost / MTok", value: summary.unitCostText, tint: amber)
                    }
                    .frame(width: 286, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }

                HStack(spacing: 12) {
                    storyChip(icon: "sparkles", label: "Top model", value: summary.topModelText, tint: mint)
                    storyChip(icon: "gauge.with.dots.needle.bottom.50percent", label: "Quota", value: summary.quotaText, tint: blue)
                    storyChip(icon: "chart.line.uptrend.xyaxis", label: "Trend", value: summary.trendText, tint: amber)
                }

                Spacer(minLength: 0)

                HStack {
                    Text(summary.generatedText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Spacer()
                    Text("#AIUsage  #BuildInPublic")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(mint)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
    }

    private var backgroundLayer: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.05, blue: 0.07),
                        Color(red: 0.07, green: 0.13, blue: 0.13),
                        Color(red: 0.02, green: 0.03, blue: 0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 27) {
                    ForEach(0..<11, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.035))
                            .frame(height: 1)
                    }
                }
                .frame(width: proxy.size.width * 1.15)
                .rotationEffect(.degrees(-7))
                .offset(y: 10)

                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(amber.opacity(0.11))
                        .frame(width: 180, height: proxy.size.height * 1.45)
                        .rotationEffect(.degrees(13))
                        .offset(x: 64)
                    Rectangle()
                        .fill(mint.opacity(0.09))
                        .frame(width: 96, height: proxy.size.height * 1.45)
                        .rotationEffect(.degrees(13))
                        .offset(x: 44)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    private func receiptMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.50))
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 8))
    }

    private func storyChip(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            SafeSystemImage(systemName: icon, fallbackName: "circle.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.46))
                Text(value)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct SafeSystemImage: View {
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
