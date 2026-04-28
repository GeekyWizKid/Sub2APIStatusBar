import Foundation

public struct Sub2APIClient: Sendable {
    public var config: AppConfig
    public var session: URLSession

    public init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func login(email: String, password: String) async throws -> AuthResponse {
        try await post("/auth/login", body: LoginRequest(email: email, password: password))
    }

    public func currentUser() async throws -> CurrentUserResponse {
        try await get("/auth/me")
    }

    public func realtimeMetrics() async throws -> RealtimeMetrics {
        try await get("/admin/dashboard/realtime")
    }

    public func dashboardSnapshot() async throws -> DashboardSnapshot {
        try await get("/admin/dashboard/snapshot-v2", query: [
            URLQueryItem(name: "include_stats", value: "true"),
            URLQueryItem(name: "include_trend", value: "true"),
            URLQueryItem(name: "granularity", value: "hour"),
        ])
    }

    public func accounts(pageSize: Int = 100) async throws -> PaginatedResponse<AccountSummary> {
        try await get("/admin/accounts", query: [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "lite", value: "true"),
        ])
    }

    public func usageDashboardStats() async throws -> DashboardStats {
        try await get("/usage/dashboard/stats")
    }

    public func usageDashboardTrend(startDate: String, endDate: String, granularity: String = "day") async throws -> DashboardTrendResponse {
        try await get("/usage/dashboard/trend", query: [
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate),
            URLQueryItem(name: "granularity", value: granularity),
        ])
    }

    public func usageDashboardModels(startDate: String, endDate: String) async throws -> DashboardModelsResponse {
        try await get("/usage/dashboard/models", query: [
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate),
        ])
    }

    public func accountUsage(id: Int64, source: String = "passive") async throws -> AccountUsageInfo {
        try await get("/admin/accounts/\(id)/usage", query: [
            URLQueryItem(name: "source", value: source),
        ])
    }

    public func subscriptionSummary() async throws -> SubscriptionSummary {
        try await get("/subscriptions/summary")
    }

    public func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        struct RefreshRequest: Encodable, Sendable {
            let refreshToken: String
        }
        return try await post("/auth/refresh", body: RefreshRequest(refreshToken: refreshToken))
    }

    public func get<Value: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> Value {
        var request = try makeRequest(path: path, query: query)
        request.httpMethod = "GET"
        return try await send(request)
    }

    public func post<Body: Encodable & Sendable, Value: Decodable & Sendable>(_ path: String, body: Body) async throws -> Value {
        var request = try makeRequest(path: path)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder.sub2api.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await send(request)
    }

    private func makeRequest(path: String, query: [URLQueryItem] = []) throws -> URLRequest {
        guard let baseURL = config.apiBaseURL else {
            throw Sub2APIError.invalidBaseURL
        }

        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(url: baseURL.appending(path: cleanPath), resolvingAgainstBaseURL: false)
        components?.queryItems = query.isEmpty ? nil : query

        guard let url = components?.url else {
            throw Sub2APIError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !config.authToken.isEmpty {
            request.setValue("Bearer \(config.authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func send<Value: Decodable & Sendable>(_ request: URLRequest) async throws -> Value {
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw Sub2APIError.badStatus(http.statusCode, message)
        }

        let decoder = JSONDecoder.sub2api
        if let envelope = try? decoder.decode(Sub2APIEnvelope<Value>.self, from: data) {
            return try envelope.value()
        }
        return try decoder.decode(Value.self, from: data)
    }
}
