import Foundation

public struct OnboardingStep: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let isComplete: Bool

    public init(id: String, title: String, detail: String, isComplete: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isComplete = isComplete
    }
}

public struct OnboardingChecklist: Equatable, Sendable {
    public let steps: [OnboardingStep]
    public let summary: String

    public init(steps: [OnboardingStep], summary: String) {
        self.steps = steps
        self.summary = summary
    }

    public static func make(form: LoginFormState, manualToken: String) -> OnboardingChecklist {
        let hasURL = !form.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAccount = !form.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPassword = !form.password.isEmpty
        let hasToken = !manualToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let steps = [
            OnboardingStep(
                id: "server-url",
                title: "Server URL",
                detail: "Root Sub2API address; /api/v1 is added automatically.",
                isComplete: hasURL
            ),
            OnboardingStep(
                id: "account",
                title: "Account",
                detail: hasToken ? "Manual token can be saved without email login." : "Email used for Sub2API login.",
                isComplete: hasAccount || hasToken
            ),
            OnboardingStep(
                id: "credential",
                title: "Password or token",
                detail: "Login with a password, or paste a bearer token.",
                isComplete: hasPassword || hasToken
            ),
        ]

        let summary: String
        if hasURL, hasToken {
            summary = "Ready to save token."
        } else if form.canSubmit {
            summary = "Ready to login."
        } else {
            let missing = steps
                .filter { !$0.isComplete }
                .map(\.summaryName)
                .joined(separator: ", ")
            summary = "Add \(missing)."
        }

        return OnboardingChecklist(steps: steps, summary: summary)
    }
}

private extension OnboardingStep {
    var summaryName: String {
        switch id {
        case "server-url":
            "server URL"
        default:
            title.lowercased()
        }
    }
}
