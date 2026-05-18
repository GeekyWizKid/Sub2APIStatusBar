import SwiftUI
import Sub2APIStatusCore

struct LoginPanel: View {
    @ObservedObject var model: MonitorViewModel

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

            VStack(alignment: .leading, spacing: 12) {
                TextField("Server URL", text: $model.settingsDraft.baseURL)
                    .textFieldStyle(.roundedBorder)

                TextField("Account", text: $model.loginEmail)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $model.loginPassword)
                    .textFieldStyle(.roundedBorder)

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
    }
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
