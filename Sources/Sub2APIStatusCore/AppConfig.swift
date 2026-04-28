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
    case admin
    case user

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .admin:
            "Admin"
        case .user:
            "User"
        }
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

    public init(
        baseURL: String,
        authToken: String = "",
        refreshToken: String = "",
        refreshIntervalSeconds: Double = 15,
        language: AppLanguage = .auto,
        monitorMode: MonitorMode = .user,
        showsMenuBarText: Bool = false
    ) {
        self.baseURL = baseURL
        self.authToken = authToken
        self.refreshToken = refreshToken
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.language = language
        self.monitorMode = monitorMode
        self.showsMenuBarText = showsMenuBarText
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
        normalize()
    }

    public static func defaults() -> AppConfig {
        let env = ProcessInfo.processInfo.environment
        return AppConfig(
            baseURL: env["SUB2API_BASE_URL"] ?? "http://127.0.0.1:8080",
            authToken: env["SUB2API_AUTH_TOKEN"] ?? "",
            refreshToken: env["SUB2API_REFRESH_TOKEN"] ?? "",
            refreshIntervalSeconds: Double(env["SUB2API_REFRESH_SECONDS"] ?? "") ?? 15,
            language: AppLanguage.fromEnvironment(env["SUB2API_LANGUAGE"]),
            monitorMode: MonitorMode(rawValue: env["SUB2API_MONITOR_MODE"] ?? "") ?? .user,
            showsMenuBarText: ["1", "true", "yes", "on"].contains((env["SUB2API_SHOW_MENU_BAR_TEXT"] ?? "").lowercased())
        )
    }

    public mutating func normalize() {
        baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        if baseURL.hasSuffix("/api/v1") {
            baseURL.removeLast("/api/v1".count)
        }

        authToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshToken = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshIntervalSeconds = min(max(refreshIntervalSeconds, 5), 300)
        monitorMode = .user
    }

    public var apiBaseURL: URL? {
        var normalized = self
        normalized.normalize()
        return URL(string: normalized.baseURL)?.appending(path: "api/v1", directoryHint: .isDirectory)
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
            return AppConfig.defaults()
        }
        decoded.normalize()
        return decoded
    }

    public func save(_ config: AppConfig) throws {
        var normalized = config
        normalized.normalize()
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(normalized).write(to: configURL, options: .atomic)
    }
}
