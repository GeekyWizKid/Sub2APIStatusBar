import SwiftUI
import Sub2APIStatusCore

struct SettingsView: View {
    @ObservedObject var model: MonitorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.bold())

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AccountSettingsSection(model: model)
                    GeneralSettingsSection(model: model)
                    AlertSettingsSection(model: model)
                    InsightSettingsSection(model: model)
                    UpdateSettingsSection(model: model)
                    LoginSettingsSection(model: model, dismiss: dismiss)
                    DiagnosticsSettingsSection(model: model)
                }
            }

            if let error = model.settingsError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    model.saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }
}

struct AccountSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        if !model.config.accounts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Accounts")
                    .font(.headline)
                Picker("Active Account", selection: Binding(
                    get: { model.config.selectedAccountID ?? "" },
                    set: { id in
                        if let account = model.config.accounts.first(where: { $0.id == id }) {
                            model.selectAccount(account)
                            model.settingsDraft = model.config
                        }
                    }
                )) {
                    ForEach(model.config.accounts) { account in
                        Text(account.displayName).tag(account.id)
                    }
                }
            }
        }
    }
}

struct GeneralSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("General")
                .font(.headline)

            VStack(spacing: 8) {
                SettingsControlRow(title: "Base URL") {
                    TextField("https://sub2api.example.com", text: $model.settingsDraft.baseURL)
                        .textFieldStyle(.roundedBorder)
                }

                SettingsControlRow(title: "Menu Bar") {
                    Toggle("Show text", isOn: $model.settingsDraft.showsMenuBarText)
                }

                SettingsControlRow(title: "Metric") {
                    Picker("", selection: $model.settingsDraft.menuBarMetric) {
                        ForEach(MenuBarMetric.allCases) { metric in
                            Text(metric.displayName).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!model.settingsDraft.showsMenuBarText)
                }

                SettingsControlRow(title: "Startup") {
                    Toggle("Launch at login", isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    ))
                }

                SettingsControlRow(title: "Refresh") {
                    Slider(value: $model.settingsDraft.refreshIntervalSeconds, in: 5...300, step: 5)
                    Text("\(Int(model.settingsDraft.refreshIntervalSeconds))s")
                        .font(.callout.monospacedDigit())
                        .frame(width: 42, alignment: .trailing)
                }

                SettingsControlRow(title: "Token") {
                    SecureField("Bearer Token", text: $model.settingsDraft.authToken)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let error = model.launchAtLoginError {
                MessageRow(message: error)
            }
        }
    }
}

struct AlertSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alerts")
                .font(.headline)

            VStack(spacing: 8) {
                SettingsControlRow(title: "Notify") {
                    Toggle("Usage insights", isOn: $model.settingsDraft.insightAlertSettings.isEnabled)
                }

                SettingsControlRow(title: "Level") {
                    Picker("", selection: $model.settingsDraft.insightAlertSettings.minimumSeverity) {
                        Text("Warning").tag(MonitorSeverity.warning)
                        Text("Error only").tag(MonitorSeverity.error)
                    }
                    .pickerStyle(.segmented)
                }

                SettingsControlRow(title: "Quiet") {
                    Slider(value: $model.settingsDraft.insightAlertSettings.cooldownMinutes, in: 5...360, step: 5)
                    Text("\(Int(model.settingsDraft.insightAlertSettings.cooldownMinutes))m")
                        .font(.callout.monospacedDigit())
                        .frame(width: 48, alignment: .trailing)
                }

                InsightNotificationPermissionRow(model: model)
            }
        }
    }
}

struct InsightSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.headline)

            VStack(spacing: 8) {
                ThresholdSliderRow(
                    title: "Quota warn",
                    value: $model.settingsDraft.insightThresholds.quotaWarningProgress,
                    range: 0.5...0.95,
                    step: 0.05,
                    valueText: StatusFormatters.percent(model.settingsDraft.insightThresholds.quotaWarningProgress)
                )

                ThresholdSliderRow(
                    title: "Quota critical",
                    value: $model.settingsDraft.insightThresholds.quotaCriticalProgress,
                    range: 0.75...1,
                    step: 0.05,
                    valueText: StatusFormatters.percent(model.settingsDraft.insightThresholds.quotaCriticalProgress)
                )

                ThresholdSliderRow(
                    title: "Balance warn",
                    value: $model.settingsDraft.insightThresholds.lowBalanceDays,
                    range: 1...14,
                    step: 1,
                    valueText: "\(Int(model.settingsDraft.insightThresholds.lowBalanceDays))d"
                )

                SettingsControlRow(title: "Monthly budget") {
                    TextField(
                        "0",
                        value: $model.settingsDraft.insightThresholds.monthlyBudgetUSD,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .textFieldStyle(.roundedBorder)
                    Text("USD")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                ThresholdSliderRow(
                    title: "Token surge",
                    value: $model.settingsDraft.insightThresholds.tokenSurgeRatio,
                    range: 1.1...3,
                    step: 0.05,
                    valueText: "\(Int(model.settingsDraft.insightThresholds.tokenSurgeRatio * 100))%"
                )

                ThresholdSliderRow(
                    title: "Spend surge",
                    value: $model.settingsDraft.insightThresholds.spendSurgeRatio,
                    range: 1.1...3,
                    step: 0.05,
                    valueText: "\(Int(model.settingsDraft.insightThresholds.spendSurgeRatio * 100))%"
                )

                ThresholdSliderRow(
                    title: "Model share",
                    value: $model.settingsDraft.insightThresholds.modelConcentrationShare,
                    range: 0.5...0.95,
                    step: 0.05,
                    valueText: StatusFormatters.percent(model.settingsDraft.insightThresholds.modelConcentrationShare)
                )

                ThresholdSliderRow(
                    title: "Latency",
                    value: $model.settingsDraft.insightThresholds.latencyWarningMs,
                    range: 5_000...60_000,
                    step: 1_000,
                    valueText: latencyThresholdText
                )
            }
        }
    }

    private var latencyThresholdText: String {
        String(format: "%.0fs", model.settingsDraft.insightThresholds.latencyWarningMs / 1_000)
    }
}

struct InsightNotificationPermissionRow: View {
    @ObservedObject var model: MonitorViewModel

    private var summary: InsightNotificationPermissionSummary {
        InsightNotificationPermissionSummary.make(
            settings: model.settingsDraft.insightAlertSettings,
            authorization: model.notificationAuthorization
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.title)
                    .font(.callout.weight(.semibold))
                Text(summary.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let action = summary.action {
                Button(actionLabel(for: action)) {
                    perform(action)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            model.refreshNotificationAuthorization()
        }
    }

    private var iconName: String {
        switch summary.action {
        case .requestPermission:
            "bell.badge"
        case .openSystemSettings:
            "bell.slash"
        case nil:
            model.settingsDraft.insightAlertSettings.isEnabled ? "bell.fill" : "bell"
        }
    }

    private var iconColor: Color {
        switch summary.action {
        case .requestPermission:
            .orange
        case .openSystemSettings:
            .red
        case nil:
            model.settingsDraft.insightAlertSettings.isEnabled ? .green : .secondary
        }
    }

    private func actionLabel(for action: InsightNotificationPermissionAction) -> String {
        switch action {
        case .requestPermission:
            "Enable"
        case .openSystemSettings:
            "Open Settings"
        }
    }

    private func perform(_ action: InsightNotificationPermissionAction) {
        switch action {
        case .requestPermission:
            model.requestNotificationAuthorization()
        case .openSystemSettings:
            model.openNotificationSettings()
        }
    }
}

struct ThresholdSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: String

    var body: some View {
        SettingsControlRow(title: title) {
            Slider(value: $value, in: range, step: step)
            Text(valueText)
                .font(.callout.monospacedDigit())
                .frame(width: 48, alignment: .trailing)
        }
    }
}

struct SettingsControlRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 76, alignment: .leading)
            HStack(spacing: 8) {
                content
            }
        }
    }
}

struct LoginSettingsSection: View {
    @ObservedObject var model: MonitorViewModel
    let dismiss: DismissAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Login")
                .font(.headline)
            TextField("Email", text: $model.loginEmail)
            SecureField("Password", text: $model.loginPassword)
            Button {
                model.loginAndSave()
            } label: {
                Label("Login and Save Account", systemImage: "person.crop.circle.badge.plus")
            }
            .disabled(!LoginFormState(baseURL: model.settingsDraft.baseURL, email: model.loginEmail, password: model.loginPassword).canSubmit || model.isLoggingIn)

            Button(role: .destructive) {
                model.disconnect()
                dismiss()
            } label: {
                Label("Remove Current Account", systemImage: "person.crop.circle.badge.xmark")
            }
            .disabled(model.config.selectedAccountID == nil && model.config.authToken.isEmpty && model.settingsDraft.authToken.isEmpty)
        }
    }
}

struct DiagnosticsSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnostics")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        model.copySocialShareCard()
                    } label: {
                        Label("Copy Share Card", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!model.snapshot.connected)

                    Button {
                        model.copyUsageReport()
                    } label: {
                        Label("Copy Usage Report", systemImage: "chart.line.text.clipboard")
                    }
                    .disabled(!model.snapshot.connected)
                }

                HStack {
                    Button {
                        model.copyDiagnostics()
                    } label: {
                        Label("Copy Diagnostics", systemImage: "doc.on.doc")
                    }

                    Button {
                        model.revealConfigFile()
                    } label: {
                        Label("Show Config", systemImage: "folder")
                    }
                }
            }
            .buttonStyle(.borderless)
        }
    }
}

struct UpdateSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Updates")
                    .font(.headline)
                Spacer()
                if model.isCheckingForUpdates {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let updateInfo = model.updateInfo, updateInfo.isUpdateAvailable {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(updateInfo.statusText)
                            .font(.callout.weight(.medium))
                        Text(updateInfo.latestRelease.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else if let message = model.updateStatusMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Checks GitHub Releases for newer versions.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    model.checkForUpdates()
                } label: {
                    Label("Check Now", systemImage: "arrow.clockwise")
                }
                .disabled(model.isCheckingForUpdates)

                if model.updateInfo?.isUpdateAvailable == true {
                    Button {
                        model.openLatestRelease()
                    } label: {
                        Label("Open Release", systemImage: "safari")
                    }
                }
            }
            .buttonStyle(.borderless)
        }
    }
}

struct UpdateAvailableBanner: View {
    let info: UpdateInfo
    let openRelease: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(info.statusText)
                    .font(.callout.weight(.semibold))
                Text("Download the latest release from GitHub.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                openRelease()
            } label: {
                Image(systemName: "safari")
            }
            .buttonStyle(.borderless)
            .help("Open release")
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
