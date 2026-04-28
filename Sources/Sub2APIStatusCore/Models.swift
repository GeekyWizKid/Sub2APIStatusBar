import Foundation

public enum Sub2APIError: Error, LocalizedError, Equatable, Sendable {
    case api(code: Int, message: String)
    case missingData
    case invalidBaseURL
    case badStatus(Int, String)

    public var errorDescription: String? {
        switch self {
        case let .api(code, message):
            "API \(code): \(message)"
        case .missingData:
            "Response did not include data."
        case .invalidBaseURL:
            "Base URL is invalid."
        case let .badStatus(status, message):
            "HTTP \(status): \(message)"
        }
    }
}

public struct Sub2APIEnvelope<Value: Decodable & Sendable>: Decodable, Sendable {
    public let code: Int
    public let message: String
    public let data: Value?

    public func value() throws -> Value {
        guard code == 0 else {
            throw Sub2APIError.api(code: code, message: message)
        }
        guard let data else {
            throw Sub2APIError.missingData
        }
        return data
    }
}

public struct LoginRequest: Encodable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct LoginFormState: Equatable, Sendable {
    public var baseURL: String
    public var email: String
    public var password: String

    public init(baseURL: String, email: String, password: String) {
        self.baseURL = baseURL
        self.email = email
        self.password = password
    }

    public var canSubmit: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }
}

public struct AuthResponse: Decodable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?
    public let tokenType: String?
    public let user: CurrentUser?
}

public struct CurrentUserResponse: Decodable, Equatable, Sendable {
    public let user: CurrentUser?

    private enum CodingKeys: String, CodingKey {
        case user
    }

    public init(user: CurrentUser?) {
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        if let wrapped = try? decoder.container(keyedBy: CodingKeys.self),
           let user = try wrapped.decodeIfPresent(CurrentUser.self, forKey: .user) {
            self.user = user
            return
        }

        user = try? CurrentUser(from: decoder)
    }
}

public struct CurrentUser: Decodable, Identifiable, Equatable, Sendable {
    public let id: Int64
    public let email: String
    public let username: String?
    public let role: String
    public let balance: Double?
    public let status: String?
}

public struct RealtimeMetrics: Decodable, Equatable, Sendable {
    public let activeRequests: Int
    public let requestsPerMinute: Double
    public let averageResponseTime: Double
    public let errorRate: Double

    public init(activeRequests: Int = 0, requestsPerMinute: Double = 0, averageResponseTime: Double = 0, errorRate: Double = 0) {
        self.activeRequests = activeRequests
        self.requestsPerMinute = requestsPerMinute
        self.averageResponseTime = averageResponseTime
        self.errorRate = errorRate
    }

    private enum CodingKeys: String, CodingKey {
        case activeRequests
        case requestsPerMinute
        case averageResponseTime
        case errorRate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeRequests = try container.decodeIfPresent(Int.self, forKey: .activeRequests) ?? 0
        requestsPerMinute = try container.decodeIfPresent(Double.self, forKey: .requestsPerMinute) ?? 0
        averageResponseTime = try container.decodeIfPresent(Double.self, forKey: .averageResponseTime) ?? 0
        errorRate = try container.decodeIfPresent(Double.self, forKey: .errorRate) ?? 0
    }
}

public struct DashboardStats: Decodable, Equatable, Sendable {
    public let totalUsers: Int
    public let activeUsers: Int
    public let totalAPIKeys: Int
    public let activeAPIKeys: Int
    public let totalAccounts: Int
    public let normalAccounts: Int
    public let errorAccounts: Int
    public let ratelimitAccounts: Int
    public let overloadAccounts: Int
    public let totalRequests: Int64
    public let totalTokens: Int64
    public let totalInputTokens: Int64
    public let totalOutputTokens: Int64
    public let totalCacheCreationTokens: Int64
    public let totalCacheReadTokens: Int64
    public let totalCost: Double
    public let totalActualCost: Double
    public let todayRequests: Int64
    public let todayTokens: Int64
    public let todayInputTokens: Int64
    public let todayOutputTokens: Int64
    public let todayCacheCreationTokens: Int64
    public let todayCacheReadTokens: Int64
    public let todayCost: Double
    public let todayActualCost: Double
    public let averageDurationMs: Double
    public let uptime: Double
    public let rpm: Double
    public let tpm: Double

    public init(
        totalUsers: Int = 0,
        activeUsers: Int = 0,
        totalAPIKeys: Int = 0,
        activeAPIKeys: Int = 0,
        totalAccounts: Int = 0,
        normalAccounts: Int = 0,
        errorAccounts: Int = 0,
        ratelimitAccounts: Int = 0,
        overloadAccounts: Int = 0,
        totalRequests: Int64 = 0,
        totalTokens: Int64 = 0,
        totalInputTokens: Int64 = 0,
        totalOutputTokens: Int64 = 0,
        totalCacheCreationTokens: Int64 = 0,
        totalCacheReadTokens: Int64 = 0,
        totalCost: Double = 0,
        totalActualCost: Double = 0,
        todayRequests: Int64 = 0,
        todayTokens: Int64 = 0,
        todayInputTokens: Int64 = 0,
        todayOutputTokens: Int64 = 0,
        todayCacheCreationTokens: Int64 = 0,
        todayCacheReadTokens: Int64 = 0,
        todayCost: Double = 0,
        todayActualCost: Double = 0,
        averageDurationMs: Double = 0,
        uptime: Double = 0,
        rpm: Double = 0,
        tpm: Double = 0
    ) {
        self.totalUsers = totalUsers
        self.activeUsers = activeUsers
        self.totalAPIKeys = totalAPIKeys
        self.activeAPIKeys = activeAPIKeys
        self.totalAccounts = totalAccounts
        self.normalAccounts = normalAccounts
        self.errorAccounts = errorAccounts
        self.ratelimitAccounts = ratelimitAccounts
        self.overloadAccounts = overloadAccounts
        self.totalRequests = totalRequests
        self.totalTokens = totalTokens
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCacheCreationTokens = totalCacheCreationTokens
        self.totalCacheReadTokens = totalCacheReadTokens
        self.totalCost = totalCost
        self.totalActualCost = totalActualCost
        self.todayRequests = todayRequests
        self.todayTokens = todayTokens
        self.todayInputTokens = todayInputTokens
        self.todayOutputTokens = todayOutputTokens
        self.todayCacheCreationTokens = todayCacheCreationTokens
        self.todayCacheReadTokens = todayCacheReadTokens
        self.todayCost = todayCost
        self.todayActualCost = todayActualCost
        self.averageDurationMs = averageDurationMs
        self.uptime = uptime
        self.rpm = rpm
        self.tpm = tpm
    }

    private enum CodingKeys: String, CodingKey {
        case totalUsers
        case activeUsers
        case totalAPIKeys = "totalApiKeys"
        case activeAPIKeys = "activeApiKeys"
        case totalAccounts
        case normalAccounts
        case errorAccounts
        case ratelimitAccounts
        case overloadAccounts
        case totalRequests
        case totalTokens
        case totalInputTokens
        case totalOutputTokens
        case totalCacheCreationTokens
        case totalCacheReadTokens
        case totalCost
        case totalActualCost
        case todayRequests
        case todayTokens
        case todayInputTokens
        case todayOutputTokens
        case todayCacheCreationTokens
        case todayCacheReadTokens
        case todayCost
        case todayActualCost
        case averageDurationMs
        case uptime
        case rpm
        case tpm
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalUsers = try container.decodeIfPresent(Int.self, forKey: .totalUsers) ?? 0
        activeUsers = try container.decodeIfPresent(Int.self, forKey: .activeUsers) ?? 0
        totalAPIKeys = try container.decodeIfPresent(Int.self, forKey: .totalAPIKeys) ?? 0
        activeAPIKeys = try container.decodeIfPresent(Int.self, forKey: .activeAPIKeys) ?? 0
        totalAccounts = try container.decodeIfPresent(Int.self, forKey: .totalAccounts) ?? 0
        normalAccounts = try container.decodeIfPresent(Int.self, forKey: .normalAccounts) ?? 0
        errorAccounts = try container.decodeIfPresent(Int.self, forKey: .errorAccounts) ?? 0
        ratelimitAccounts = try container.decodeIfPresent(Int.self, forKey: .ratelimitAccounts) ?? 0
        overloadAccounts = try container.decodeIfPresent(Int.self, forKey: .overloadAccounts) ?? 0
        totalRequests = try container.decodeIfPresent(Int64.self, forKey: .totalRequests) ?? 0
        totalTokens = try container.decodeIfPresent(Int64.self, forKey: .totalTokens) ?? 0
        totalInputTokens = try container.decodeIfPresent(Int64.self, forKey: .totalInputTokens) ?? 0
        totalOutputTokens = try container.decodeIfPresent(Int64.self, forKey: .totalOutputTokens) ?? 0
        totalCacheCreationTokens = try container.decodeIfPresent(Int64.self, forKey: .totalCacheCreationTokens) ?? 0
        totalCacheReadTokens = try container.decodeIfPresent(Int64.self, forKey: .totalCacheReadTokens) ?? 0
        totalCost = try container.decodeIfPresent(Double.self, forKey: .totalCost) ?? 0
        totalActualCost = try container.decodeIfPresent(Double.self, forKey: .totalActualCost) ?? 0
        todayRequests = try container.decodeIfPresent(Int64.self, forKey: .todayRequests) ?? 0
        todayTokens = try container.decodeIfPresent(Int64.self, forKey: .todayTokens) ?? 0
        todayInputTokens = try container.decodeIfPresent(Int64.self, forKey: .todayInputTokens) ?? 0
        todayOutputTokens = try container.decodeIfPresent(Int64.self, forKey: .todayOutputTokens) ?? 0
        todayCacheCreationTokens = try container.decodeIfPresent(Int64.self, forKey: .todayCacheCreationTokens) ?? 0
        todayCacheReadTokens = try container.decodeIfPresent(Int64.self, forKey: .todayCacheReadTokens) ?? 0
        todayCost = try container.decodeIfPresent(Double.self, forKey: .todayCost) ?? 0
        todayActualCost = try container.decodeIfPresent(Double.self, forKey: .todayActualCost) ?? 0
        averageDurationMs = try container.decodeIfPresent(Double.self, forKey: .averageDurationMs) ?? 0
        uptime = try container.decodeIfPresent(Double.self, forKey: .uptime) ?? 0
        rpm = try container.decodeIfPresent(Double.self, forKey: .rpm) ?? 0
        tpm = try container.decodeIfPresent(Double.self, forKey: .tpm) ?? 0
    }
}

public struct ModelUsageSummary: Decodable, Identifiable, Equatable, Sendable {
    public var id: String { model }

    public let model: String
    public let requests: Int64
    public let totalTokens: Int64
    public let inputTokens: Int64
    public let outputTokens: Int64
    public let cacheCreationTokens: Int64
    public let cacheReadTokens: Int64
    public let cost: Double
    public let actualCost: Double
    public let accountCost: Double
    public let standardCost: Double

    public init(
        model: String,
        requests: Int64 = 0,
        totalTokens: Int64 = 0,
        inputTokens: Int64 = 0,
        outputTokens: Int64 = 0,
        cacheCreationTokens: Int64 = 0,
        cacheReadTokens: Int64 = 0,
        cost: Double = 0,
        actualCost: Double = 0,
        accountCost: Double = 0,
        standardCost: Double = 0
    ) {
        self.model = model
        self.requests = requests
        self.totalTokens = totalTokens
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.cacheReadTokens = cacheReadTokens
        self.cost = cost
        self.actualCost = actualCost
        self.accountCost = accountCost
        self.standardCost = standardCost
    }

    private enum CodingKeys: String, CodingKey {
        case model
        case requests
        case totalTokens
        case inputTokens
        case outputTokens
        case cacheCreationTokens
        case cacheReadTokens
        case cost
        case actualCost
        case accountCost
        case standardCost
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? "Unknown"
        requests = try container.decodeIfPresent(Int64.self, forKey: .requests) ?? 0
        totalTokens = try container.decodeIfPresent(Int64.self, forKey: .totalTokens) ?? 0
        inputTokens = try container.decodeIfPresent(Int64.self, forKey: .inputTokens) ?? 0
        outputTokens = try container.decodeIfPresent(Int64.self, forKey: .outputTokens) ?? 0
        cacheCreationTokens = try container.decodeIfPresent(Int64.self, forKey: .cacheCreationTokens) ?? 0
        cacheReadTokens = try container.decodeIfPresent(Int64.self, forKey: .cacheReadTokens) ?? 0
        cost = try container.decodeIfPresent(Double.self, forKey: .cost) ?? 0
        actualCost = try container.decodeIfPresent(Double.self, forKey: .actualCost) ?? 0
        accountCost = try container.decodeIfPresent(Double.self, forKey: .accountCost) ?? actualCost
        standardCost = try container.decodeIfPresent(Double.self, forKey: .standardCost) ?? cost
    }
}

public struct TrendDataPoint: Decodable, Identifiable, Equatable, Sendable {
    public var id: String { date }

    public let date: String
    public let requests: Int64
    public let inputTokens: Int64
    public let outputTokens: Int64
    public let cacheCreationTokens: Int64
    public let cacheReadTokens: Int64
    public let totalTokens: Int64
    public let cost: Double
    public let actualCost: Double

    public init(
        date: String,
        requests: Int64 = 0,
        inputTokens: Int64 = 0,
        outputTokens: Int64 = 0,
        cacheCreationTokens: Int64 = 0,
        cacheReadTokens: Int64 = 0,
        totalTokens: Int64 = 0,
        cost: Double = 0,
        actualCost: Double = 0
    ) {
        self.date = date
        self.requests = requests
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.cacheReadTokens = cacheReadTokens
        self.totalTokens = totalTokens
        self.cost = cost
        self.actualCost = actualCost
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case requests
        case inputTokens
        case outputTokens
        case cacheCreationTokens
        case cacheReadTokens
        case totalTokens
        case cost
        case actualCost
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        requests = try container.decodeIfPresent(Int64.self, forKey: .requests) ?? 0
        inputTokens = try container.decodeIfPresent(Int64.self, forKey: .inputTokens) ?? 0
        outputTokens = try container.decodeIfPresent(Int64.self, forKey: .outputTokens) ?? 0
        cacheCreationTokens = try container.decodeIfPresent(Int64.self, forKey: .cacheCreationTokens) ?? 0
        cacheReadTokens = try container.decodeIfPresent(Int64.self, forKey: .cacheReadTokens) ?? 0
        totalTokens = try container.decodeIfPresent(Int64.self, forKey: .totalTokens) ?? 0
        cost = try container.decodeIfPresent(Double.self, forKey: .cost) ?? 0
        actualCost = try container.decodeIfPresent(Double.self, forKey: .actualCost) ?? 0
    }
}

public struct DashboardTrendResponse: Decodable, Equatable, Sendable {
    public let startDate: String?
    public let endDate: String?
    public let granularity: String?
    public let trend: [TrendDataPoint]

    public init(startDate: String? = nil, endDate: String? = nil, granularity: String? = nil, trend: [TrendDataPoint] = []) {
        self.startDate = startDate
        self.endDate = endDate
        self.granularity = granularity
        self.trend = trend
    }
}

public struct DashboardModelsResponse: Decodable, Equatable, Sendable {
    public let startDate: String?
    public let endDate: String?
    public let models: [ModelUsageSummary]

    public init(startDate: String? = nil, endDate: String? = nil, models: [ModelUsageSummary] = []) {
        self.startDate = startDate
        self.endDate = endDate
        self.models = models
    }
}

public struct DashboardSnapshot: Decodable, Equatable, Sendable {
    public let generatedAt: String?
    public let stats: DashboardStats?
    public let trend: [TrendDataPoint]?
    public let modelDistribution: [ModelUsageSummary]?

    private enum CodingKeys: String, CodingKey {
        case generatedAt
        case stats
        case trend
        case modelDistribution
        case modelStats
        case modelUsage
        case models
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt)
        stats = try container.decodeIfPresent(DashboardStats.self, forKey: .stats)
        trend = try container.decodeIfPresent([TrendDataPoint].self, forKey: .trend)
        modelDistribution = try container.decodeIfPresent([ModelUsageSummary].self, forKey: .modelDistribution)
            ?? container.decodeIfPresent([ModelUsageSummary].self, forKey: .modelStats)
            ?? container.decodeIfPresent([ModelUsageSummary].self, forKey: .modelUsage)
            ?? container.decodeIfPresent([ModelUsageSummary].self, forKey: .models)
    }
}

public struct PaginatedResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    public let items: [Item]
    public let total: Int
    public let page: Int
    public let pageSize: Int
    public let pages: Int

    public init(items: [Item] = [], total: Int = 0, page: Int = 1, pageSize: Int = 0, pages: Int = 0) {
        self.items = items
        self.total = total
        self.page = page
        self.pageSize = pageSize
        self.pages = pages
    }

    private enum CodingKeys: String, CodingKey {
        case items
        case total
        case page
        case pageSize
        case pages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([Item].self, forKey: .items) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? items.count
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize) ?? items.count
        pages = try container.decodeIfPresent(Int.self, forKey: .pages) ?? 1
    }
}

public struct AccountSummary: Decodable, Identifiable, Equatable, Sendable {
    public let id: Int64
    public let name: String
    public let platform: String
    public let type: String
    public let status: String
    public let schedulable: Bool
    public let quotaLimit: Double?
    public let quotaUsed: Double?
    public let quotaDailyLimit: Double?
    public let quotaDailyUsed: Double?
    public let quotaWeeklyLimit: Double?
    public let quotaWeeklyUsed: Double?
    public let errorMessage: String
    public let rateLimitResetAt: String?

    public init(
        id: Int64,
        name: String,
        platform: String,
        type: String,
        status: String,
        schedulable: Bool,
        quotaLimit: Double?,
        quotaUsed: Double?,
        quotaDailyLimit: Double?,
        quotaDailyUsed: Double?,
        quotaWeeklyLimit: Double?,
        quotaWeeklyUsed: Double?,
        errorMessage: String,
        rateLimitResetAt: String?
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.type = type
        self.status = status
        self.schedulable = schedulable
        self.quotaLimit = quotaLimit
        self.quotaUsed = quotaUsed
        self.quotaDailyLimit = quotaDailyLimit
        self.quotaDailyUsed = quotaDailyUsed
        self.quotaWeeklyLimit = quotaWeeklyLimit
        self.quotaWeeklyUsed = quotaWeeklyUsed
        self.errorMessage = errorMessage
        self.rateLimitResetAt = rateLimitResetAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case platform
        case type
        case status
        case schedulable
        case quotaLimit
        case quotaUsed
        case quotaDailyLimit
        case quotaDailyUsed
        case quotaWeeklyLimit
        case quotaWeeklyUsed
        case errorMessage
        case rateLimitResetAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Account"
        platform = try container.decodeIfPresent(String.self, forKey: .platform) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        schedulable = try container.decodeIfPresent(Bool.self, forKey: .schedulable) ?? (status == "active")
        quotaLimit = try container.decodeIfPresent(Double.self, forKey: .quotaLimit)
        quotaUsed = try container.decodeIfPresent(Double.self, forKey: .quotaUsed)
        quotaDailyLimit = try container.decodeIfPresent(Double.self, forKey: .quotaDailyLimit)
        quotaDailyUsed = try container.decodeIfPresent(Double.self, forKey: .quotaDailyUsed)
        quotaWeeklyLimit = try container.decodeIfPresent(Double.self, forKey: .quotaWeeklyLimit)
        quotaWeeklyUsed = try container.decodeIfPresent(Double.self, forKey: .quotaWeeklyUsed)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage) ?? ""
        rateLimitResetAt = try container.decodeIfPresent(String.self, forKey: .rateLimitResetAt)
    }

    public var highestQuotaRatio: Double? {
        [
            ratio(used: quotaUsed, limit: quotaLimit),
            ratio(used: quotaDailyUsed, limit: quotaDailyLimit),
            ratio(used: quotaWeeklyUsed, limit: quotaWeeklyLimit),
        ].compactMap(\.self).max()
    }

    private func ratio(used: Double?, limit: Double?) -> Double? {
        guard let used, let limit, limit > 0 else {
            return nil
        }
        return used / limit
    }
}

public struct AccountHealthSummary: Equatable, Sendable {
    public let total: Int
    public let active: Int
    public let schedulable: Int
    public let blocked: Int
    public let nearQuotaLimit: Int

    public init(accounts: [AccountSummary]) {
        total = accounts.count
        active = accounts.filter { $0.status == "active" }.count
        schedulable = accounts.filter(\.schedulable).count
        blocked = accounts.filter { !$0.schedulable || $0.status != "active" || !$0.errorMessage.isEmpty }.count
        nearQuotaLimit = accounts.filter { ($0.highestQuotaRatio ?? 0) >= 0.9 }.count
    }
}

public struct SubscriptionSummary: Decodable, Equatable, Sendable {
    public let activeCount: Int
    public let totalUsedUSD: Double
    public let subscriptions: [SubscriptionSummaryItem]

    public init(activeCount: Int, totalUsedUSD: Double = 0, subscriptions: [SubscriptionSummaryItem]) {
        self.activeCount = activeCount
        self.totalUsedUSD = totalUsedUSD
        self.subscriptions = subscriptions
    }

    private enum CodingKeys: String, CodingKey {
        case activeCount
        case totalUsedUSD = "totalUsedUsd"
        case subscriptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subscriptions = try container.decodeIfPresent([SubscriptionSummaryItem].self, forKey: .subscriptions) ?? []
        activeCount = try container.decodeIfPresent(Int.self, forKey: .activeCount) ?? subscriptions.filter { $0.status == "active" }.count
        totalUsedUSD = try container.decodeIfPresent(Double.self, forKey: .totalUsedUSD) ?? 0
    }

    public var highestProgress: Double {
        subscriptions.flatMap { [$0.dailyProgress, $0.weeklyProgress, $0.monthlyProgress] }
            .compactMap(\.self)
            .max() ?? 0
    }

    public var expiringSoonCount: Int {
        subscriptions.filter { item in
            guard let days = item.daysRemaining else {
                return false
            }
            return days <= 3
        }.count
    }
}

public struct SubscriptionSummaryItem: Decodable, Identifiable, Equatable, Sendable {
    public let id: Int64
    public let groupName: String
    public let status: String
    public let dailyUsedUSD: Double?
    public let dailyLimitUSD: Double?
    public let weeklyUsedUSD: Double?
    public let weeklyLimitUSD: Double?
    public let monthlyUsedUSD: Double?
    public let monthlyLimitUSD: Double?
    public let dailyResetInSeconds: Double?
    public let weeklyResetInSeconds: Double?
    public let monthlyResetInSeconds: Double?
    public let dailyProgress: Double?
    public let weeklyProgress: Double?
    public let monthlyProgress: Double?
    public let expiresAt: String?
    public let daysRemaining: Int?

    public init(
        id: Int64,
        groupName: String,
        status: String,
        dailyUsedUSD: Double? = nil,
        dailyLimitUSD: Double? = nil,
        weeklyUsedUSD: Double? = nil,
        weeklyLimitUSD: Double? = nil,
        monthlyUsedUSD: Double? = nil,
        monthlyLimitUSD: Double? = nil,
        dailyResetInSeconds: Double? = nil,
        weeklyResetInSeconds: Double? = nil,
        monthlyResetInSeconds: Double? = nil,
        dailyProgress: Double?,
        weeklyProgress: Double?,
        monthlyProgress: Double?,
        expiresAt: String?,
        daysRemaining: Int?
    ) {
        self.id = id
        self.groupName = groupName
        self.status = status
        self.dailyUsedUSD = dailyUsedUSD
        self.dailyLimitUSD = dailyLimitUSD
        self.weeklyUsedUSD = weeklyUsedUSD
        self.weeklyLimitUSD = weeklyLimitUSD
        self.monthlyUsedUSD = monthlyUsedUSD
        self.monthlyLimitUSD = monthlyLimitUSD
        self.dailyResetInSeconds = dailyResetInSeconds
        self.weeklyResetInSeconds = weeklyResetInSeconds
        self.monthlyResetInSeconds = monthlyResetInSeconds
        self.dailyProgress = dailyProgress
        self.weeklyProgress = weeklyProgress
        self.monthlyProgress = monthlyProgress
        self.expiresAt = expiresAt
        self.daysRemaining = daysRemaining
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case groupName
        case status
        case dailyUsedUSD = "dailyUsedUsd"
        case dailyLimitUSD = "dailyLimitUsd"
        case weeklyUsedUSD = "weeklyUsedUsd"
        case weeklyLimitUSD = "weeklyLimitUsd"
        case monthlyUsedUSD = "monthlyUsedUsd"
        case monthlyLimitUSD = "monthlyLimitUsd"
        case dailyResetInSeconds
        case weeklyResetInSeconds
        case monthlyResetInSeconds
        case dailyProgress
        case weeklyProgress
        case monthlyProgress
        case expiresAt
        case daysRemaining
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName) ?? "Subscription"
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        dailyUsedUSD = try container.decodeIfPresent(Double.self, forKey: .dailyUsedUSD)
        dailyLimitUSD = try container.decodeIfPresent(Double.self, forKey: .dailyLimitUSD)
        weeklyUsedUSD = try container.decodeIfPresent(Double.self, forKey: .weeklyUsedUSD)
        weeklyLimitUSD = try container.decodeIfPresent(Double.self, forKey: .weeklyLimitUSD)
        monthlyUsedUSD = try container.decodeIfPresent(Double.self, forKey: .monthlyUsedUSD)
        monthlyLimitUSD = try container.decodeIfPresent(Double.self, forKey: .monthlyLimitUSD)
        dailyResetInSeconds = try container.decodeIfPresent(Double.self, forKey: .dailyResetInSeconds)
        weeklyResetInSeconds = try container.decodeIfPresent(Double.self, forKey: .weeklyResetInSeconds)
        monthlyResetInSeconds = try container.decodeIfPresent(Double.self, forKey: .monthlyResetInSeconds)
        dailyProgress = try container.decodeIfPresent(Double.self, forKey: .dailyProgress)
            ?? Self.ratio(used: dailyUsedUSD, limit: dailyLimitUSD)
        weeklyProgress = try container.decodeIfPresent(Double.self, forKey: .weeklyProgress)
            ?? Self.ratio(used: weeklyUsedUSD, limit: weeklyLimitUSD)
        monthlyProgress = try container.decodeIfPresent(Double.self, forKey: .monthlyProgress)
            ?? Self.ratio(used: monthlyUsedUSD, limit: monthlyLimitUSD)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        daysRemaining = try container.decodeIfPresent(Int.self, forKey: .daysRemaining)
    }

    private static func ratio(used: Double?, limit: Double?) -> Double? {
        guard let used, let limit, limit > 0 else {
            return nil
        }
        return used / limit
    }
}

public struct UsageProgress: Decodable, Equatable, Sendable {
    public let used: Double?
    public let limit: Double?
    public let percentage: Double?
    public let utilization: Double?
    public let resetsAt: String?
    public let resetInSeconds: Double?

    public var normalizedPercentage: Double {
        if let percentage {
            return percentage > 1 ? percentage / 100 : percentage
        }
        if let utilization {
            return utilization > 1 ? utilization / 100 : utilization
        }
        guard let used, let limit, limit > 0 else {
            return 0
        }
        return used / limit
    }
}

public struct AccountUsageInfo: Decodable, Equatable, Sendable {
    public let source: String?
    public let updatedAt: String?
    public let fiveHour: UsageProgress?
    public let sevenDay: UsageProgress?
    public let sevenDaySonnet: UsageProgress?
    public let error: String?
    public let errorCode: String?
    public let needsReauth: Bool?
    public let needsVerify: Bool?
    public let isBanned: Bool?
}

public enum MonitorSeverity: String, Equatable, Sendable {
    case healthy
    case warning
    case error
}

public struct MonitorSnapshot: Equatable, Sendable {
    public let mode: MonitorMode
    public let connected: Bool
    public let currentUser: CurrentUser?
    public let stats: DashboardStats?
    public let trend: [TrendDataPoint]?
    public let modelDistribution: [ModelUsageSummary]?
    public let realtime: RealtimeMetrics?
    public let accountHealth: AccountHealthSummary?
    public let subscriptionSummary: SubscriptionSummary?
    public let lastUpdatedAt: Date?
    public let message: String?

    public init(
        mode: MonitorMode,
        connected: Bool,
        currentUser: CurrentUser? = nil,
        stats: DashboardStats?,
        trend: [TrendDataPoint]? = nil,
        modelDistribution: [ModelUsageSummary]? = nil,
        realtime: RealtimeMetrics?,
        accountHealth: AccountHealthSummary?,
        subscriptionSummary: SubscriptionSummary?,
        lastUpdatedAt: Date?,
        message: String?
    ) {
        self.mode = mode
        self.connected = connected
        self.currentUser = currentUser
        self.stats = stats
        self.trend = trend
        self.modelDistribution = modelDistribution
        self.realtime = realtime
        self.accountHealth = accountHealth
        self.subscriptionSummary = subscriptionSummary
        self.lastUpdatedAt = lastUpdatedAt
        self.message = message
    }

    public static func idle(mode: MonitorMode) -> MonitorSnapshot {
        MonitorSnapshot(
            mode: mode,
            connected: false,
            stats: nil,
            realtime: nil,
            accountHealth: nil,
            subscriptionSummary: nil,
            lastUpdatedAt: nil,
            message: "Not connected"
        )
    }

    public var severity: MonitorSeverity {
        if !connected {
            return .error
        }

        if (realtime?.errorRate ?? 0) >= 0.1 {
            return .error
        }

        if let accountHealth, accountHealth.total > 0 {
            let blockedRatio = Double(accountHealth.blocked) / Double(accountHealth.total)
            if blockedRatio >= 0.5 {
                return .error
            }
            if accountHealth.nearQuotaLimit > 0 || blockedRatio > 0 {
                return .warning
            }
        }

        if let subscriptionSummary {
            if subscriptionSummary.highestProgress >= 0.95 {
                return .error
            }
            if subscriptionSummary.highestProgress >= 0.8 || subscriptionSummary.expiringSoonCount > 0 {
                return .warning
            }
        }

        return .healthy
    }

    public var statusLabel: String {
        if !connected {
            return "Disconnected"
        }

        if let subscriptionSummary {
            if subscriptionSummary.highestProgress >= 0.95 {
                return "Near Limit"
            }
            if subscriptionSummary.highestProgress >= 0.8 {
                return "High Usage"
            }
            if subscriptionSummary.expiringSoonCount > 0 {
                return "Expiring Soon"
            }
        }

        return switch severity {
        case .healthy:
            "OK"
        case .warning:
            "Warn"
        case .error:
            "Error"
        }
    }

    public var menuBarSummary: String {
        guard connected else {
            return "Sub2API \(statusLabel)"
        }

        if let stats {
            return "\(StatusFormatters.currency(stats.todayActualCost)) · \(StatusFormatters.menuBarCount(stats.todayRequests)) req · \(StatusFormatters.menuBarRate(stats.rpm)) RPM"
        }

        if let subscriptionSummary {
            return "\(subscriptionSummary.activeCount) subs · \(StatusFormatters.percent(subscriptionSummary.highestProgress)) peak"
        }

        return "Sub2API \(statusLabel)"
    }
}
