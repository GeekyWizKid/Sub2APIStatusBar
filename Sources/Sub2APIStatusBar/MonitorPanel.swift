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
                VStack(spacing: 0) {
                    header
                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            statusSection

                            if let updateInfo = model.updateInfo, updateInfo.isUpdateAvailable {
                                UpdateAvailableBanner(info: updateInfo) {
                                    model.openLatestRelease()
                                }
                            }

                            userSection

                            if let message = model.snapshot.message, !message.isEmpty {
                                MessageRow(message: message)
                            }
                        }
                        .padding(16)
                    }

                    Divider()
                    footer
                }
            }
        }
        .frame(width: 520, height: 680)
        .sheet(isPresented: $showingSettings) {
            SettingsView(model: model)
                .frame(width: 450, height: 690)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(activeAccountTitle)
                    .font(.headline)
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
        .padding(16)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.snapshot.statusLabel)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(iconColor)
                Spacer()
                Text("User Usage")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            if model.config.authToken.isEmpty {
                Text("Set Base URL and token to start monitoring.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if model.snapshot.connected {
                UsageInsightsView(insights: usageInsights)
            }
        }
    }

    private var userSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let user = model.snapshot.currentUser {
                UserAccountCard(user: user)
            }

            if let stats = model.snapshot.stats {
                MetricGrid(items: [
                    MetricItem(title: "Balance", value: balanceText, caption: "Available", systemImage: "banknote", tint: .green),
                    MetricItem(title: "API Keys", value: "\(stats.totalAPIKeys)", caption: "\(stats.activeAPIKeys) active", systemImage: "key", tint: .blue),
                    MetricItem(title: "Today Requests", value: StatusFormatters.menuBarCount(stats.todayRequests), caption: "Total \(StatusFormatters.compactNumber(stats.totalRequests))", systemImage: "chart.bar", tint: .green),
                    MetricItem(title: "Today Cost", value: StatusFormatters.preciseCurrency(stats.todayActualCost), caption: "Total \(StatusFormatters.preciseCurrency(stats.totalActualCost))", systemImage: "dollarsign.circle", tint: .purple),
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

            SectionBlock(title: "Token Trend") {
                TokenTrendSection(state: TokenTrendDisplayState.make(points: model.snapshot.trend))
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
        .padding(12)
    }

    private var iconName: String {
        switch model.snapshot.severity {
        case .healthy:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch model.snapshot.severity {
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
        return "Updated \(date.formatted(date: .omitted, time: .shortened))"
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
