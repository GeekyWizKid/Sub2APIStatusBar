import SwiftUI
import Sub2APIStatusCore

struct ModelDistributionView: View {
    let models: [ModelUsageSummary]

    private var visibleModels: [ModelUsageSummary] {
        Array(models.prefix(5))
    }

    private var maximumTokens: Double {
        max(Double(visibleModels.map(\.totalTokens).max() ?? 0), 1)
    }

    var body: some View {
        SectionBlock(title: "Model Distribution") {
            VStack(spacing: 10) {
                ForEach(visibleModels) { item in
                    VStack(spacing: 7) {
                        HStack {
                            Text(item.model)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Spacer()
                            Text(StatusFormatters.preciseCurrency(item.actualCost))
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.green)
                        }
                        HStack {
                            Text("\(StatusFormatters.menuBarCount(item.requests)) requests")
                            Spacer()
                            Text(StatusFormatters.compactNumber(item.totalTokens))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        ProgressView(value: Double(item.totalTokens) / maximumTokens)
                            .tint(.blue)
                    }
                    if item.id != visibleModels.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct TokenTrendSection: View {
    let state: TokenTrendDisplayState

    var body: some View {
        switch state {
        case let .chart(points):
            TokenTrendView(points: points)
                .frame(height: 150)
        case let .unavailable(message):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        }
    }
}

struct TokenTrendView: View {
    let points: [TrendDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                ZStack {
                    trendPath(values: points.map { Double($0.cacheReadTokens) }, in: proxy.size)
                        .fill(Color.cyan.opacity(0.16))
                    trendPath(values: points.map { Double($0.cacheReadTokens) }, in: proxy.size)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    trendPath(values: points.map { Double($0.inputTokens) }, in: proxy.size)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    trendPath(values: points.map { Double($0.outputTokens) }, in: proxy.size)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }

            HStack(spacing: 12) {
                LegendDot(color: .blue, label: "Input")
                LegendDot(color: .green, label: "Output")
                LegendDot(color: .cyan, label: "Cache Read")
                Spacer()
                Text(points.last?.date ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)
        }
    }

    private func trendPath(values: [Double], in size: CGSize) -> Path {
        let maximum = max(values.max() ?? 0, 1)
        var path = Path()
        for index in values.indices {
            let x = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
            let y = size.height - (size.height * CGFloat(values[index] / maximum))
            if index == values.startIndex {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
        }
    }
}
