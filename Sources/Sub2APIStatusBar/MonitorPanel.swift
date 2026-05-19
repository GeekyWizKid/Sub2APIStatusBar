import SwiftUI
import Sub2APIStatusCore

struct MonitorPanel: View {
    @ObservedObject var model: MonitorViewModel
    @State private var showingSettings = false

    var body: some View {
        Group {
            if model.config.authToken.isEmpty {
                LoginPanel(model: model)
            } else {
                ZStack {
                    PanelBackground()
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        header

                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                statusSection

                                if model.snapshot.connected {
                                    OverviewCard(
                                        statusText: statusLabel,
                                        statusColor: iconColor,
                                        stats: model.snapshot.stats,
                                        balanceText: balanceText,
                                        quotaText: quotaHeadline,
                                        tokenBreakdown: tokenBreakdown
                                    )

                                    shareToolbar

                                    SectionBlock(title: "Usage Trend") {
                                        UsageTrendSection(state: UsageTrendDisplayState.make(points: model.snapshot.trend))
                                    }
                                }

                                if let updateInfo = model.updateInfo, updateInfo.isUpdateAvailable {
                                    UpdateAvailableBanner(info: updateInfo) {
                                        model.openLatestRelease()
                                    }
                                }

                                userSection

                                if let message = model.snapshot.message, !message.isEmpty {
                                    MessageRow(message: message)
                                }

                                if let suggestion = model.snapshotRecoverySuggestion {
                                    RecoverySuggestionCard(suggestion: suggestion) { action in
                                        model.performRecoveryAction(action)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                        }

                        Divider()
                        footer
                    }
                }
            }
        }
        .frame(width: 520, height: 680)
        .sheet(isPresented: $showingSettings) {
            SettingsView(model: model)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(activeAccountTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(model.snapshot.connected ? lastUpdatedText : "Disconnected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !model.config.accounts.isEmpty {
                AccountSwitcher(model: model)
            }

            Button {
                model.refresh()
            } label: {
                Image(systemName: model.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
            }
            .disabled(model.isRefreshing)
            .help("Refresh")

            Button {
                model.settingsDraft = model.config
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .help("Settings")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(PanelColors.elevatedSurface.opacity(0.82))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PanelColors.border)
                .frame(height: 1)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.config.authToken.isEmpty {
                Text("Set Base URL and token to start monitoring.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if model.snapshot.connected {
                UsageInsightsView(insights: usageInsights)
            }
        }
    }

    private var shareToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    model.copySocialShareCard()
                } label: {
                    Label("Share Card", systemImage: "square.and.arrow.up")
                }

                Button {
                    model.copyUsageReport()
                } label: {
                    Label("Report", systemImage: "doc.on.doc")
                }

                Button {
                    model.openSocialShareDraft()
                } label: {
                    Label("Post", systemImage: "paperplane")
                }

                Spacer()
            }

            if let message = model.updateStatusMessage, message.hasPrefix("Share") || message == "Usage report copied." {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
        .padding(10)
        .background(PanelColors.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PanelColors.border, lineWidth: 1)
        )
    }

    private var userSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let user = model.snapshot.currentUser {
                UserAccountCard(user: user)
            }

            if let stats = model.snapshot.stats {
                Text("Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                MetricGrid(items: [
                    MetricItem(title: "Balance", value: balanceText, caption: "Available", systemImage: "banknote", tint: .green),
                    MetricItem(title: "API Keys", value: "\(stats.totalAPIKeys)", caption: "\(stats.activeAPIKeys) active", systemImage: "key", tint: .blue),
                    MetricItem(title: "Today Requests", value: StatusFormatters.menuBarCount(stats.todayRequests), caption: "Total \(StatusFormatters.compactNumber(stats.totalRequests))", systemImage: "chart.bar", tint: .green),
                    MetricItem(title: "Today Cost", value: StatusFormatters.preciseCurrency(stats.todayActualCost), caption: "Total \(StatusFormatters.preciseCurrency(stats.totalActualCost))", systemImage: "dollarsign.circle", tint: .purple),
                    MetricItem(title: "Cost / MTok", value: StatusFormatters.costPerMillionTokens(cost: stats.todayActualCost, tokens: stats.todayTokens), caption: "Today blended", systemImage: "divide.circle", tint: .teal),
                    MetricItem(title: "Today Tokens", value: StatusFormatters.compactNumber(stats.todayTokens), caption: tokenBreakdown(input: stats.todayInputTokens, output: stats.todayOutputTokens), systemImage: "cube", tint: .orange),
                    MetricItem(title: "Total Tokens", value: StatusFormatters.compactNumber(stats.totalTokens), caption: tokenBreakdown(input: stats.totalInputTokens, output: stats.totalOutputTokens), systemImage: "archivebox.fill", tint: .indigo),
                    MetricItem(title: "Performance", value: "\(StatusFormatters.menuBarRate(stats.rpm)) RPM", caption: "\(StatusFormatters.compactNumber(Int64(stats.tpm))) TPM", systemImage: "bolt", tint: .purple),
                    MetricItem(title: "Avg Response", value: latencyText(milliseconds: stats.averageDurationMs), caption: "Average time", systemImage: "clock", tint: .pink),
                ])
            }

            if let summary = model.snapshot.subscriptionSummary {
                if model.snapshot.stats == nil {
                    MetricGrid(items: [
                        MetricItem(title: "Balance", value: balanceText, systemImage: "banknote", tint: .green),
                        MetricItem(title: "Active Subs", value: "\(summary.activeCount)", systemImage: "checkmark.seal", tint: .green),
                        MetricItem(title: "Peak Usage", value: StatusFormatters.percent(summary.highestProgress), systemImage: "gauge.with.dots.needle.67percent", tint: .orange),
                        MetricItem(title: "Total Used", value: StatusFormatters.preciseCurrency(summary.totalUsedUSD), systemImage: "dollarsign.circle", tint: .purple),
                    ])
                }

                SectionBlock(title: "Subscriptions") {
                    VStack(spacing: 10) {
                        ForEach(summary.subscriptions.prefix(5)) { item in
                            SubscriptionQuotaCard(item: item)
                        }
                    }
                }
            }

            if let models = model.snapshot.modelDistribution, !models.isEmpty {
                ModelDistributionView(models: models)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                model.openDashboard()
            } label: {
                Label("Open", systemImage: "safari")
            }
            .disabled(model.config.baseURL.isEmpty)

            Spacer()

            Button {
                model.quit()
            } label: {
                Label("Quit", systemImage: "power")
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(PanelColors.elevatedSurface.opacity(0.86))
    }

    private var iconName: String {
        switch severity {
        case .healthy:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch severity {
        case .healthy:
            .green
        case .warning:
            .orange
        case .error:
            .red
        }
    }

    private var lastUpdatedText: String {
        guard let date = model.snapshot.lastUpdatedAt else {
            return "Waiting for first refresh"
        }
        let updated = "Updated \(date.formatted(date: .omitted, time: .shortened))"
        return isStale ? "\(updated) · stale" : updated
    }

    private var activeAccountTitle: String {
        model.config.selectedAccount?.displayName ?? "Sub2API"
    }

    private var balanceText: String {
        guard let balance = model.snapshot.currentUser?.balance else {
            return "--"
        }
        return StatusFormatters.currency(balance)
    }

    private var quotaHeadline: String {
        guard let summary = model.snapshot.subscriptionSummary else {
            return "No quota data"
        }
        let progress = StatusFormatters.percent(summary.highestProgress)
        return "\(progress) peak"
    }

    private var usageInsights: UsageInsights {
        UsageInsights.make(
            currentUser: model.snapshot.currentUser,
            stats: model.snapshot.stats,
            subscriptionSummary: model.snapshot.subscriptionSummary,
            trend: model.snapshot.trend,
            models: model.snapshot.modelDistribution,
            thresholds: model.config.insightThresholds
        )
    }

    private var severity: MonitorSeverity {
        model.snapshot.severity(now: model.now, refreshIntervalSeconds: model.config.refreshIntervalSeconds)
    }

    private var statusLabel: String {
        model.snapshot.statusLabel(now: model.now, refreshIntervalSeconds: model.config.refreshIntervalSeconds)
    }

    private var isStale: Bool {
        model.snapshot.isStale(now: model.now, refreshIntervalSeconds: model.config.refreshIntervalSeconds)
    }

    private func tokenBreakdown(input: Int64, output: Int64) -> String {
        "In \(StatusFormatters.compactNumber(input)) / Out \(StatusFormatters.compactNumber(output))"
    }

    private func latencyText(milliseconds: Double) -> String {
        if milliseconds >= 1_000 {
            return String(format: "%.2fs", milliseconds / 1_000)
        }
        return "\(Int(milliseconds))ms"
    }

}

struct AccountSwitcher: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        Menu {
            ForEach(model.config.accounts) { account in
                Button {
                    model.selectAccount(account)
                } label: {
                    Label(account.displayName, systemImage: account.id == model.config.selectedAccountID ? "checkmark.circle.fill" : "person.crop.circle")
                }
            }
        } label: {
            Image(systemName: "person.2")
        }
        .menuStyle(.borderlessButton)
        .help("Switch account")
    }
}

struct OverviewCard: View {
    let statusText: String
    let statusColor: Color
    let stats: DashboardStats?
    let balanceText: String
    let quotaText: String
    let tokenBreakdown: (Int64, Int64) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    StatusPill(text: statusText, color: statusColor, systemImage: "circle.fill")
                    Text("Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(balanceText)
                        .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                    Text("balance")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let stats {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(StatusFormatters.compactNumber(stats.todayTokens))
                        .font(.system(size: 48, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text("tokens")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    OverviewStat(title: "Spend", value: StatusFormatters.preciseCurrency(stats.todayActualCost), color: .green)
                    OverviewStat(title: "Requests", value: StatusFormatters.menuBarCount(stats.todayRequests), color: .blue)
                    OverviewStat(title: "Quota", value: quotaText, color: .orange)
                }

                Text(tokenBreakdown(stats.todayInputTokens, stats.todayOutputTokens))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("Waiting for usage data.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor).opacity(0.96),
                    Color(red: 0.88, green: 0.93, blue: 1.0).opacity(0.64),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PanelColors.border, lineWidth: 1)
        )
    }
}

struct OverviewStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }
}
