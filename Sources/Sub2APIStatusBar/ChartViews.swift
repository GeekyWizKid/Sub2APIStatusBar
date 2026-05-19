import SwiftUI
import Sub2APIStatusCore

struct ModelDistributionView: View {
    let models: [ModelUsageSummary]

    private var visibleModels: [ModelUsageDisplay] {
        ModelUsageDisplay.make(models)
    }

    var body: some View {
        SectionBlock(title: "Model Distribution") {
            VStack(spacing: 0) {
                ForEach(visibleModels) { item in
                    VStack(spacing: 8) {
                        HStack {
                            Text(item.model)
                                .font(.callout.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            Text(item.costText)
                                .font(.callout.weight(.bold).monospacedDigit())
                                .foregroundStyle(.green)
                        }
                        HStack {
                            Text(item.costShareText)
                                .foregroundStyle(.green)
                            Text(item.costPerMillionTokensText)
                            Spacer()
                            Text(item.requestsText)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        ProgressView(value: item.costProgress)
                            .tint(.green)
                        HStack {
                            Text(item.tokenMixText)
                            Spacer()
                            Text(item.tokensText)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        ProgressView(value: item.tokenProgress)
                            .tint(.blue.opacity(0.75))
                    }
                    .padding(.vertical, 8)
                    if item.id != visibleModels.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct UsageTrendSection: View {
    let state: UsageTrendDisplayState
    @State private var selectedMode: UsageTrendMode = .tokens

    var body: some View {
        switch state {
        case let .chart(points):
            VStack(alignment: .leading, spacing: 10) {
                Picker("", selection: $selectedMode) {
                    ForEach(UsageTrendMode.allCases) { mode in
                        Text(UsageTrendMetric(mode: mode, points: points).title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)

                UsageTrendView(metric: UsageTrendMetric(mode: selectedMode, points: points))
                    .frame(height: 154)
            }
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
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
        }
    }
}

struct UsageTrendView: View {
    let metric: UsageTrendMetric

    private let palette: [Color] = [.blue, .green, .cyan, .orange]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .font(.caption.weight(.semibold))
                    Text(metric.latestDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(metric.latestValue)
                    .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            GeometryReader { proxy in
                ZStack {
                    chartGuideLines(in: proxy.size)
                        .stroke(Color.secondary.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))

                    ForEach(Array(metric.series.enumerated()), id: \.element.id) { index, series in
                        let color = palette[index % palette.count]
                        trendPath(values: series.values, maximum: metric.maximum, in: proxy.size)
                            .stroke(color, style: StrokeStyle(lineWidth: index == 0 ? 2.6 : 2, lineCap: .round, lineJoin: .round))
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(Array(metric.series.enumerated()), id: \.element.id) { index, series in
                    LegendDot(color: palette[index % palette.count], label: series.label)
                }
                Spacer()
            }
            .font(.caption2)
        }
    }

    private func trendPath(values: [Double], maximum: Double, in size: CGSize) -> Path {
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

    private func chartGuideLines(in size: CGSize) -> Path {
        var path = Path()
        for fraction in [0.25, 0.5, 0.75] {
            let y = size.height * CGFloat(fraction)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
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
