import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case auto
    case zhHans
    case en

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .auto:
            "Auto"
        case .zhHans:
            "简体中文"
        case .en:
            "English"
        }
    }

    public static func fromEnvironment(_ value: String?) -> AppLanguage {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !value.isEmpty else {
            return .auto
        }

        switch value {
        case "zh", "zh-cn", "zh-hans", "cn", "chinese":
            return .zhHans
        case "en", "en-us", "english":
            return .en
        default:
            return .auto
        }
    }
}

public enum MonitorMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case user

    public var id: String { rawValue }

    public var displayName: String {
        "User"
    }

    public init(from _: Decoder) throws {
        self = .user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct StoredAccount: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var email: String
    public var baseURL: String
    public var authToken: String
    public var refreshToken: String

    public init(
        id: String = UUID().uuidString,
        name: String = "",
        email: String = "",
        baseURL: String,
        authToken: String = "",
        refreshToken: String = ""
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.baseURL = baseURL
        self.authToken = authToken
        self.refreshToken = refreshToken
        normalize()
    }

    public mutating func normalize() {
        id = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if id.isEmpty {
            id = UUID().uuidString
        }

        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        baseURL = AppConfig.normalizedBaseURL(baseURL)
        authToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshToken = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var displayName: String {
        if !name.isEmpty {
            return name
        }
        if !email.isEmpty {
            return email
        }
        return baseURL
    }

    public var detailText: String {
        if !email.isEmpty, email != displayName {
            return email
        }
        return baseURL
    }

    public var storedTokens: StoredAuthTokens {
        StoredAuthTokens(authToken: authToken, refreshToken: refreshToken)
    }
}

public struct AppConfig: Codable, Equatable, Sendable {
    public var baseURL: String
    public var authToken: String
    public var refreshToken: String
    public var refreshIntervalSeconds: Double
    public var language: AppLanguage
    public var monitorMode: MonitorMode
    public var showsMenuBarText: Bool
    public var accounts: [StoredAccount]
    public var selectedAccountID: String?

    public init(
        baseURL: String,
        authToken: String = "",
        refreshToken: String = "",
        refreshIntervalSeconds: Double = 15,
        language: AppLanguage = .auto,
        monitorMode: MonitorMode = .user,
        showsMenuBarText: Bool = false,
        accounts: [StoredAccount] = [],
        selectedAccountID: String? = nil
    ) {
        self.baseURL = baseURL
        self.authToken = authToken
        self.refreshToken = refreshToken
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.language = language
        self.monitorMode = monitorMode
        self.showsMenuBarText = showsMenuBarText
        self.accounts = accounts
        self.selectedAccountID = selectedAccountID
        normalize()
    }

    private enum CodingKeys: String, CodingKey {
        case baseURL
        case authToken
        case refreshToken
        case refreshIntervalSeconds
        case language
        case monitorMode
        case showsMenuBarText
        case accounts
        case selectedAccountID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? "http://127.0.0.1:8080"
        authToken = try container.decodeIfPresent(String.self, forKey: .authToken) ?? ""
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken) ?? ""
        refreshIntervalSeconds = try container.decodeIfPresent(Double.self, forKey: .refreshIntervalSeconds) ?? 15
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .auto
        monitorMode = try container.decodeIfPresent(MonitorMode.self, forKey: .monitorMode) ?? .user
        showsMenuBarText = try container.decodeIfPresent(Bool.self, forKey: .showsMenuBarText) ?? false
        accounts = try container.decodeIfPresent([StoredAccount].self, forKey: .accounts) ?? []
        selectedAccountID = try container.decodeIfPresent(String.self, forKey: .selectedAccountID)
        normalize()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(authToken, forKey: .authToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(refreshIntervalSeconds, forKey: .refreshIntervalSeconds)
        try container.encode(language, forKey: .language)
        try container.encode(monitorMode, forKey: .monitorMode)
        try container.encode(showsMenuBarText, forKey: .showsMenuBarText)
        try container.encode(accounts, forKey: .accounts)
        try container.encodeIfPresent(selectedAccountID, forKey: .selectedAccountID)
    }

    public static func defaults() -> AppConfig {
        let env = ProcessInfo.processInfo.environment
        return AppConfig(
            baseURL: env["SUB2API_BASE_URL"] ?? "http://127.0.0.1:8080",
            authToken: env["SUB2API_AUTH_TOKEN"] ?? "",
            refreshToken: env["SUB2API_REFRESH_TOKEN"] ?? "",
            refreshIntervalSeconds: Double(env["SUB2API_REFRESH_SECONDS"] ?? "") ?? 15,
            language: AppLanguage.fromEnvironment(env["SUB2API_LANGUAGE"]),
            monitorMode: .user,
            showsMenuBarText: ["1", "true", "yes", "on"].contains((env["SUB2API_SHOW_MENU_BAR_TEXT"] ?? "").lowercased())
        )
    }

    public mutating func normalize() {
        baseURL = Self.normalizedBaseURL(baseURL)
        authToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshToken = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshIntervalSeconds = min(max(refreshIntervalSeconds, 5), 300)
        monitorMode = .user

        accounts = accounts.map { account in
            var normalized = account
            normalized.normalize()
            return normalized
        }

        var seenAccountIDs = Set<String>()
        accounts = accounts.filter { account in
            guard !seenAccountIDs.contains(account.id) else {
                return false
            }
            seenAccountIDs.insert(account.id)
            return true
        }

        selectedAccountID = selectedAccountID?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let selectedAccountID, accounts.contains(where: { $0.id == selectedAccountID }) {
            self.selectedAccountID = selectedAccountID
        } else {
            selectedAccountID = accounts.first?.id
        }
    }

    public mutating func clearAuthTokens() {
        authToken = ""
        refreshToken = ""
    }

    public var selectedAccount: StoredAccount? {
        guard let selectedAccountID else {
            return nil
        }
        return accounts.first { $0.id == selectedAccountID }
    }

    public mutating func applySelectedAccountBaseURL() {
        guard let selectedAccount else {
            return
        }
        baseURL = selectedAccount.baseURL
    }

    public mutating func syncSelectedAccountFromRuntime() {
        normalize()
        guard let selectedAccountID,
              let index = accounts.firstIndex(where: { $0.id == selectedAccountID }) else {
            return
        }
        accounts[index].baseURL = baseURL
        accounts[index].normalize()
    }

    @discardableResult
    public mutating func upsertAccount(
        name: String = "",
        email: String = "",
        baseURL: String? = nil,
        tokens: StoredAuthTokens? = nil
    ) -> String {
        let accountBaseURL = Self.normalizedBaseURL(baseURL ?? self.baseURL)
        let accountEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let accountName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingIndex = accounts.firstIndex { account in
            if !accountEmail.isEmpty {
                return account.email.caseInsensitiveCompare(accountEmail) == .orderedSame
                    && account.baseURL == accountBaseURL
            }
            return account.id == selectedAccountID || (account.email.isEmpty && account.baseURL == accountBaseURL)
        }

        let index: Int
        if let matchingIndex {
            index = matchingIndex
            accounts[index].name = accountName.isEmpty ? accounts[index].name : accountName
            accounts[index].email = accountEmail
            accounts[index].baseURL = accountBaseURL
            if let tokens {
                accounts[index].authToken = tokens.authToken
                accounts[index].refreshToken = tokens.refreshToken
            }
            accounts[index].normalize()
        } else {
            var account = StoredAccount(
                name: accountName.isEmpty ? accountEmail : accountName,
                email: accountEmail,
                baseURL: accountBaseURL,
                authToken: tokens?.authToken ?? "",
                refreshToken: tokens?.refreshToken ?? ""
            )
            account.normalize()
            accounts.append(account)
            index = accounts.index(before: accounts.endIndex)
        }

        selectedAccountID = accounts[index].id
        self.baseURL = accounts[index].baseURL
        if let tokens {
            authToken = tokens.authToken
            refreshToken = tokens.refreshToken
        }
        normalize()
        return accounts[index].id
    }

    public mutating func selectAccount(id: String, tokens: StoredAuthTokens) {
        selectedAccountID = id
        applySelectedAccountBaseURL()
        authToken = tokens.authToken
        refreshToken = tokens.refreshToken
        normalize()
        applySelectedAccountBaseURL()
    }

    public static func normalizedBaseURL(_ value: String) -> String {
        var normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        if normalized.hasSuffix("/api/v1") {
            normalized.removeLast("/api/v1".count)
        }
        return normalized
    }

    public var apiBaseURL: URL? {
        var normalized = self
        normalized.normalize()
        return URL(string: normalized.baseURL)?.appending(path: "api/v1", directoryHint: .isDirectory)
    }
}

public struct StoredAuthTokens: Equatable, Sendable {
    public var authToken: String
    public var refreshToken: String

    public init(authToken: String = "", refreshToken: String = "") {
        self.authToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.refreshToken = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isEmpty: Bool {
        authToken.isEmpty && refreshToken.isEmpty
    }
}

public final class ConfigStore: Sendable {
    private let configURL: URL

    public init(configURL: URL? = nil) {
        if let configURL {
            self.configURL = configURL
            return
        }

        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appending(path: "Library/Application Support", directoryHint: .isDirectory)
        self.configURL = baseDir
            .appending(path: "Sub2APIStatusBar", directoryHint: .isDirectory)
            .appending(path: "config.json")
    }

    public func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configURL),
              var decoded = try? JSONDecoder.sub2api.decode(AppConfig.self, from: data) else {
            var defaults = AppConfig.defaults()
            let envTokens = StoredAuthTokens(authToken: defaults.authToken, refreshToken: defaults.refreshToken)
            if !envTokens.isEmpty {
                defaults.upsertAccount(name: "Environment Account", baseURL: defaults.baseURL, tokens: envTokens)
            }
            return defaults
        }

        let topLevelTokens = StoredAuthTokens(authToken: decoded.authToken, refreshToken: decoded.refreshToken)
        decoded.normalize()

        if decoded.accounts.isEmpty, !topLevelTokens.isEmpty {
            decoded.upsertAccount(name: "Default Account", baseURL: decoded.baseURL, tokens: topLevelTokens)
            decoded.normalize()
            return decoded
        }

        if let selectedAccountID = decoded.selectedAccountID {
            let tokens = loadTokens(in: decoded, for: selectedAccountID)
            decoded.selectAccount(id: selectedAccountID, tokens: tokens)
        } else {
            decoded.clearAuthTokens()
        }

        return decoded
    }

    public func save(_ config: AppConfig) throws {
        var normalized = config
        normalized.normalize()
        let tokens = StoredAuthTokens(authToken: normalized.authToken, refreshToken: normalized.refreshToken)
        if normalized.selectedAccountID == nil, !tokens.isEmpty {
            normalized.upsertAccount(name: "Default Account", baseURL: normalized.baseURL, tokens: tokens)
        } else {
            normalized.syncSelectedAccountFromRuntime()
        }

        if let accountID = normalized.selectedAccountID {
            saveTokens(tokens, in: &normalized, for: accountID)
        }
        try writeConfig(normalized)
    }

    public func loadTokens(for accountID: String) -> StoredAuthTokens {
        let config = load()
        return loadTokens(in: config, for: accountID)
    }

    public func deleteTokens(for accountID: String) throws {
        var config = load()
        saveTokens(StoredAuthTokens(), in: &config, for: accountID)
        if config.selectedAccountID == accountID {
            config.clearAuthTokens()
        }
        try writeConfig(config)
    }

    private func writeConfig(_ config: AppConfig) throws {
        var normalized = config
        normalized.normalize()
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(normalized).write(to: configURL, options: .atomic)
    }

    private func loadTokens(in config: AppConfig, for accountID: String) -> StoredAuthTokens {
        config.accounts.first { $0.id == accountID }?.storedTokens ?? StoredAuthTokens()
    }

    private func saveTokens(_ tokens: StoredAuthTokens, in config: inout AppConfig, for accountID: String) {
        guard let index = config.accounts.firstIndex(where: { $0.id == accountID }) else {
            return
        }
        config.accounts[index].authToken = tokens.authToken
        config.accounts[index].refreshToken = tokens.refreshToken
        config.accounts[index].normalize()
    }
}
