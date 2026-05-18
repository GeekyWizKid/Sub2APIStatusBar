import SwiftUI
import Sub2APIStatusCore

struct LoginPanel: View {
    @ObservedObject var model: MonitorViewModel
    @FocusState private var focusedField: FocusedLoginField?

    private var formState: LoginFormState {
        LoginFormState(
            baseURL: model.settingsDraft.baseURL,
            email: model.loginEmail,
            password: model.loginPassword
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sub2API")
                        .font(.title2.bold())
                    Text("Connect your server")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if !model.config.accounts.isEmpty {
                AccountListSection(model: model)
            }

            OnboardingChecklistView(checklist: checklist)

            VStack(alignment: .leading, spacing: 12) {
                TextField("Server URL", text: $model.settingsDraft.baseURL)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .serverURL)

                TextField("Account", text: $model.loginEmail)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .email)

                SecureField("Password", text: $model.loginPassword)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .password)

                HStack {
                    Text("Refresh")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Slider(value: $model.settingsDraft.refreshIntervalSeconds, in: 5...300, step: 5)
                    Text("\(Int(model.settingsDraft.refreshIntervalSeconds))s")
                        .font(.callout.monospacedDigit())
                        .frame(width: 42, alignment: .trailing)
                }
            }

            RecoverySuggestionCard(suggestion: model.loginRecoverySuggestion) { action in
                performRecoveryAction(action)
            }

            if let error = model.settingsError {
                MessageRow(message: error)
            }

            Button {
                model.loginAndSave()
            } label: {
                HStack {
                    if model.isLoggingIn {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "key.fill")
                    }
                    Text(model.isLoggingIn ? "Connecting..." : "Login")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!formState.canSubmit || model.isLoggingIn)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Manual token")
                    .font(.headline)
                SecureField("Bearer Token", text: $model.settingsDraft.authToken)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .token)
                Button {
                    model.settingsDraft.upsertAccount(
                        name: model.loginEmail,
                        email: model.loginEmail,
                        baseURL: model.settingsDraft.baseURL,
                        tokens: StoredAuthTokens(authToken: model.settingsDraft.authToken, refreshToken: model.settingsDraft.refreshToken)
                    )
                    model.saveSettings()
                } label: {
                    Label("Save Token", systemImage: "square.and.arrow.down")
                }
                .disabled(model.settingsDraft.authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()

            HStack {
                Button {
                    model.openURL(model.settingsDraft.baseURL)
                } label: {
                    Label("Open Server", systemImage: "safari")
                }
                .disabled(model.settingsDraft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Button {
                    model.quit()
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(20)
        .onChange(of: model.focusesManualToken) { shouldFocus in
            if shouldFocus {
                focusedField = .token
                model.focusesManualToken = false
            }
        }
    }

    private var checklist: OnboardingChecklist {
        OnboardingChecklist.make(
            form: formState,
            manualToken: model.settingsDraft.authToken
        )
    }

    private func performRecoveryAction(_ action: RecoveryActionKind) {
        model.performRecoveryAction(action)
        switch action {
        case .enterURL, .openServer:
            focusedField = .serverURL
        case .login:
            focusedField = model.loginEmail.isEmpty ? .email : .password
        case .replaceToken:
            focusedField = .token
        case .retry:
            break
        }
    }
}

struct OnboardingChecklistView: View {
    let checklist: OnboardingChecklist

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Connection Checklist")
                    .font(.headline)
                Spacer()
                Text(checklist.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            ForEach(checklist.steps) { step in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(step.isComplete ? Color.green : .secondary)
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.callout.weight(.medium))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private enum FocusedLoginField: Hashable {
    case serverURL
    case email
    case password
    case token
}

struct AccountListSection: View {
    @ObservedObject var model: MonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accounts")
                .font(.headline)

            ForEach(model.config.accounts) { account in
                Button {
                    model.selectAccount(account)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: account.id == model.config.selectedAccountID ? "checkmark.circle.fill" : "person.crop.circle")
                            .foregroundStyle(account.id == model.config.selectedAccountID ? Color.accentColor : .secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.displayName)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Text(account.detailText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
