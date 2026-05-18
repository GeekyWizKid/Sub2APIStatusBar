import Foundation

public enum RecoveryActionKind: String, Equatable, Sendable {
    case enterURL
    case openServer
    case login
    case replaceToken
    case retry
}

public struct RecoveryAction: Identifiable, Equatable, Sendable {
    public let kind: RecoveryActionKind
    public let label: String
    public let systemImage: String

    public var id: RecoveryActionKind { kind }

    public init(kind: RecoveryActionKind, label: String, systemImage: String) {
        self.kind = kind
        self.label = label
        self.systemImage = systemImage
    }
}

public struct RecoverySuggestion: Equatable, Sendable {
    public let title: String
    public let detail: String
    public let actions: [RecoveryAction]

    public init(title: String, detail: String, actions: [RecoveryAction]) {
        self.title = title
        self.detail = detail
        self.actions = actions
    }

    public static func make(message: String?, hasBaseURL: Bool, hasToken: Bool) -> RecoverySuggestion {
        let normalized = (message ?? "").lowercased()

        if !hasBaseURL || normalized.contains("base url") || normalized.contains("url is invalid") {
            return RecoverySuggestion(
                title: "Add your server URL",
                detail: "Use the root Sub2API server address. The app adds /api/v1 automatically.",
                actions: [
                    RecoveryAction(kind: .enterURL, label: "Enter URL", systemImage: "link"),
                    RecoveryAction(kind: .openServer, label: "Open Server", systemImage: "safari"),
                ]
            )
        }

        if normalized.contains("401") || normalized.contains("unauthorized") || normalized.contains("expired") {
            return RecoverySuggestion(
                title: "Sign in again",
                detail: "Your saved session is no longer accepted. Login again or replace the bearer token.",
                actions: [
                    RecoveryAction(kind: .login, label: "Login", systemImage: "key.fill"),
                    RecoveryAction(kind: .replaceToken, label: "Replace Token", systemImage: "square.and.pencil"),
                ]
            )
        }

        if normalized.contains("timed out")
            || normalized.contains("could not connect")
            || normalized.contains("network")
            || normalized.contains("offline")
            || normalized.contains("cannot find host") {
            return RecoverySuggestion(
                title: "Check server reachability",
                detail: "Open the Sub2API server in your browser, then retry when it responds.",
                actions: [
                    RecoveryAction(kind: .openServer, label: "Open Server", systemImage: "safari"),
                    RecoveryAction(kind: .retry, label: "Retry", systemImage: "arrow.clockwise"),
                ]
            )
        }

        if !hasToken {
            return RecoverySuggestion(
                title: "Connect an account",
                detail: "Login with your Sub2API account or paste a bearer token to start monitoring.",
                actions: [
                    RecoveryAction(kind: .login, label: "Login", systemImage: "key.fill"),
                    RecoveryAction(kind: .replaceToken, label: "Use Token", systemImage: "square.and.pencil"),
                ]
            )
        }

        return RecoverySuggestion(
            title: "Refresh or inspect settings",
            detail: "Retry the request. If it still fails, check the server URL and token in Settings.",
            actions: [
                RecoveryAction(kind: .retry, label: "Retry", systemImage: "arrow.clockwise"),
                RecoveryAction(kind: .openServer, label: "Open Server", systemImage: "safari"),
            ]
        )
    }
}
