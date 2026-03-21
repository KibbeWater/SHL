//
//  SHLAPIClient.swift
//  SHLNetwork
//
//  Created by Claude Code
//

import Foundation

// MARK: - Protocols for Dependency Injection

/// Protocol for keychain operations needed by the API client
public protocol KeychainProviding: Sendable {
    func getToken() -> String?
    func getDeviceId() -> String
}

/// Protocol for authentication operations needed by the API client
public protocol AuthenticationProviding: Sendable {
    func refreshToken() async throws
}

// MARK: - HTTP Method Enum

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Empty Response for 204 No Content

public struct EmptyResponse: Codable {
    public init() {}
}

// MARK: - Paginated Response

public struct PaginatedResponse<T: Decodable>: Decodable {
    public let data: [T]
    public let page: Int
    public let limit: Int
    public let total: Int
}

// MARK: - Dummy Auth Provider (used during initialization before real auth is set)

private struct DummyAuthProvider: AuthenticationProviding {
    func refreshToken() async throws {
        throw SHLAPIError.unauthorized
    }
}

// MARK: - API Client

public class SHLAPIClient {
    /// Shared singleton instance. Uses KeychainManager.shared and a deferred auth provider.
    /// Call `setAuthProvider(_:)` after AuthenticationManager is initialized.
    public static let shared: SHLAPIClient = {
        let client = SHLAPIClient(
            keychain: KeychainManager.shared,
            authProvider: DummyAuthProvider()
        )
        return client
    }()

    private let baseURL: String
    private let decoder: JSONDecoder
    private let keychain: KeychainProviding
    private var authManager: AuthenticationProviding

    /// Flag to prevent recursive token refresh attempts
    private var isRefreshingToken = false

    /// Track in-flight token refresh continuations to prevent concurrent refresh attempts
    private var refreshContinuations: [CheckedContinuation<Void, Error>] = []

    /// Set the real authentication provider (call after AuthenticationManager.shared is available)
    public func setAuthProvider(_ provider: AuthenticationProviding) {
        self.authManager = provider
    }

    public init(
        keychain: KeychainProviding,
        authProvider: AuthenticationProviding,
        baseURL: String? = nil
    ) {
        self.keychain = keychain
        self.authManager = authProvider
        self.baseURL = baseURL
            ?? ProcessInfo.processInfo.environment["SHL_API_BASE_URL"]
            ?? "https://api.lrlnet.se"

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Generic Request (APIEndpoint)

    /// Execute a request using a typed APIEndpoint
    public func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw SHLAPIError.invalidURL
        }

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw SHLAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.timeoutInterval = 30
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw SHLAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SHLAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SHLAPIError.map(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw SHLAPIError.decodingError(underlying: decodingError)
        }
    }

    // MARK: - Generic Request (String Endpoint)

    /// Execute a request using a string endpoint path with optional auth
    public func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]

        // Add JWT token if required
        if requiresAuth {
            guard let token = keychain.getToken() else {
                throw SHLAPIError.unauthorized
            }
            headers["Authorization"] = "Bearer \(token)"
        }

        // Build URL
        guard let url = URL(string: "\(baseURL)/api/v1\(endpoint)") else {
            throw SHLAPIError.invalidURL
        }

        #if DEBUG
        print("API Request: \(method.rawValue) \(url.absoluteString)")
        #endif

        // Build request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.timeoutInterval = 30
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Add body if present
        if let body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
            #if DEBUG
            if let bodyData = urlRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                print("Request body: \(bodyString)")
            }
            #endif
        }

        // Execute request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw SHLAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SHLAPIError.invalidResponse
        }

        #if DEBUG
        print("API Response: \(httpResponse.statusCode) (\(data.count) bytes)")
        #endif

        // Handle 401 Unauthorized - token expired
        if httpResponse.statusCode == 401 && requiresAuth {
            #if DEBUG
            print("Received 401 Unauthorized for: \(endpoint)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("401 Response body: \(responseString)")
            }
            #endif

            // Check if this is the refresh endpoint itself - don't try to refresh again
            if endpoint == "/auth/refresh" {
                #if DEBUG
                print("Token refresh itself returned 401, token is invalid")
                #endif
                throw SHLAPIError.unauthorized
            }

            // If a refresh is already in progress, wait for it to complete
            if isRefreshingToken {
                #if DEBUG
                print("Token refresh already in progress, waiting for it to complete...")
                #endif

                // Wait for the ongoing refresh to complete
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    refreshContinuations.append(continuation)
                }

                #if DEBUG
                print("Token refresh completed, retrying original request...")
                #endif

                // Retry request with new token
                return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
            }

            // No refresh in progress, start a new one
            isRefreshingToken = true

            #if DEBUG
            print("Attempting to refresh token...")
            #endif

            do {
                try await authManager.refreshToken()

                #if DEBUG
                print("Token refreshed successfully")
                #endif

                // Resume all waiting continuations with success
                for continuation in refreshContinuations {
                    continuation.resume()
                }
                refreshContinuations.removeAll()
                isRefreshingToken = false

                #if DEBUG
                print("Retrying original request with new token...")
                #endif

                // Retry request with new token
                return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
            } catch {
                #if DEBUG
                print("Token refresh failed: \(error)")
                #endif

                // Resume all waiting continuations with failure
                for continuation in refreshContinuations {
                    continuation.resume(throwing: error)
                }
                refreshContinuations.removeAll()
                isRefreshingToken = false

                throw SHLAPIError.unauthorized
            }
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            #if DEBUG
            print("API Error: \(httpResponse.statusCode) for \(endpoint)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response body: \(responseString)")
            }
            #endif
            throw SHLAPIError.map(statusCode: httpResponse.statusCode, data: data)
        }

        // Handle empty response for 201 Created
        if httpResponse.statusCode == 201 && data.isEmpty {
            if T.self == EmptyResponse.self {
                guard let result = EmptyResponse() as? T else {
                    throw SHLAPIError.invalidResponse
                }
                return result
            }
        }

        // Handle empty response for 204 No Content
        if httpResponse.statusCode == 204 {
            if T.self == EmptyResponse.self {
                guard let result = EmptyResponse() as? T else {
                    throw SHLAPIError.invalidResponse
                }
                return result
            }
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw SHLAPIError.decodingError(underlying: decodingError)
        }
    }

    // MARK: - Match Endpoints

    public func getLatestMatches() async throws -> [Match] {
        let response: PaginatedResponse<Match> = try await request(.latestMatches(page: 1, limit: 20))
        return response.data
    }

    /// Search matches with optional filters and pagination
    public func searchMatches(
        date: String? = nil,
        team: String? = nil,
        season: String? = nil,
        state: String? = nil,
        descending: Bool = false,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> PaginatedResponse<Match> {
        try await request(.searchMatches(
            date: date,
            team: team,
            season: season,
            state: state,
            descending: descending,
            page: page,
            limit: limit
        ))
    }

    public func getLiveMatches() async throws -> [Match] {
        try await request(.liveMatches)
    }

    public func getLiveMatch(id: String) async throws -> LiveMatch {
        try await request(.getLiveMatch(id: id))
    }

    public func getMatchDetail(id: String) async throws -> Match {
        try await request(.matchDetail(id: id))
    }

    public func getMatchStats(id: String) async throws -> [MatchStats] {
        try await request(.matchStats(id: id))
    }

    /// Get match events as rich DTOs
    public func getMatchEvents(id: String) async throws -> [PBPEventDTO] {
        try await request(.matchEvents(id: id))
    }

    /// Get match events wrapped in a PBPController for easy manipulation
    public func getMatchPBPController(id: String) async throws -> PBPController {
        let events: [PBPEventDTO] = try await request(.matchEvents(id: id))
        var seenIDs = Set<String>()
        let uniqueEvents = events.filter { event in
            if seenIDs.contains(event.id) {
                return false
            } else {
                seenIDs.insert(event.id)
                return true
            }
        }
        return await PBPController(events: uniqueEvents)
    }

    public func getSeasonMatches(seasonCode: String) async throws -> [Match] {
        try await request(.seasonMatches(seasonCode: seasonCode))
    }

    public func getRecentMatches(limit: Int = 10) async throws -> RecentMatchesResponse {
        try await request(.recentMatches(limit: limit))
    }

    // MARK: - Team Endpoints

    public func getTeams() async throws -> [Team] {
        try await request(.teams)
    }

    public func getTeamDetail(id: String) async throws -> Team {
        try await request(.teamDetail(id: id))
    }

    public func getTeamRoster(id: String) async throws -> [Player] {
        try await request(.teamRoster(id: id))
    }

    public func getTeamMatches(id: String) async throws -> [Match] {
        try await request(.teamMatches(id: id))
    }

    // MARK: - Player Endpoints

    public func getPlayerDetail(id: String) async throws -> Player {
        try await request(.playerDetail(id: id))
    }

    public func getPlayerStats(id: String) async throws -> [PlayerGameLog] {
        try await request(.playerStats(id: id))
    }

    // MARK: - Season/League Endpoints

    public func getCurrentSeason() async throws -> Season {
        try await request(.currentSeason)
    }

    public func getCurrentSeasonInfo() async throws -> SeasonInfoResponse {
        try await request(.currentSeasonInfo)
    }

    public func getAllSeasons() async throws -> [Season] {
        try await request(.allSeasons)
    }

    public func getStandings(seasonId: String) async throws -> [Standings] {
        try await request(.standings(seasonId: seasonId))
    }

    public func getCurrentStandings() async throws -> [Standings] {
        try await request(.currentStandings)
    }

    // MARK: - User Management Endpoints

    /// Update notification settings
    public func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettingsResponse {
        try await request(
            endpoint: "/user/notifications",
            method: .patch,
            body: settings,
            requiresAuth: true
        )
    }

    /// Get user's interested teams
    public func getInterestedTeams() async throws -> InterestedTeamsResponse {
        try await request(
            endpoint: "/user/interested-teams",
            method: .get,
            requiresAuth: true
        )
    }

    /// Add a team to interested teams
    public func addInterestedTeam(teamId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/user/interested-teams/\(teamId)",
            method: .post,
            requiresAuth: true
        )
    }

    /// Remove a team from interested teams
    public func removeInterestedTeam(teamId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/user/interested-teams/\(teamId)",
            method: .delete,
            requiresAuth: true
        )
    }

    /// Set all interested teams at once (replaces existing)
    public func setInterestedTeams(teamIds: [String]) async throws -> InterestedTeamsResponse {
        try await request(
            endpoint: "/user/interested-teams",
            method: .put,
            body: SetInterestedTeamsRequest(teamIds: teamIds),
            requiresAuth: true
        )
    }

    /// Register push notification token
    public func registerPushToken(_ request: RegisterPushTokenRequest) async throws -> RegisterPushTokenResponse {
        try await self.request(
            endpoint: "/push-tokens/register",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }

    /// Register push token with type and optional team code (convenience method for push-to-start)
    public func registerPushToken(token: String, type: String, deviceId: String, teamCode: String? = nil) async throws -> RegisterPushTokenResponse {
        let environment: String
        #if DEBUG
        environment = "development"
        #else
        environment = "production"
        #endif

        let request = RegisterPushTokenRequest(
            token: token,
            deviceId: deviceId,
            type: type,
            teamCode: teamCode,
            environment: environment
        )

        return try await registerPushToken(request)
    }

    /// Get all devices
    public func getDevices() async throws -> DevicesResponse {
        try await request(
            endpoint: "/devices",
            method: .get,
            requiresAuth: true
        )
    }

    /// Update device name or notification settings
    public func updateDevice(deviceId: String, name: String? = nil, notificationsEnabled: Bool? = nil) async throws {
        let request = UpdateDeviceRequest(deviceName: name, notificationsEnabled: notificationsEnabled)
        let _: EmptyResponse = try await self.request(
            endpoint: "/devices/\(deviceId)",
            method: .put,
            body: request,
            requiresAuth: true
        )
    }

    /// Remove device
    public func removeDevice(deviceId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/devices/\(deviceId)",
            method: .delete,
            requiresAuth: true
        )
    }

    /// Get all push tokens
    public func getPushTokens() async throws -> PushTokensResponse {
        try await request(
            endpoint: "/push-tokens",
            method: .get,
            requiresAuth: true
        )
    }

    /// Delete push token
    public func deletePushToken(tokenId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/push-tokens/\(tokenId)",
            method: .delete,
            requiresAuth: true
        )
    }

    /// Register push token for live match subscription
    public func registerLiveActivityToken(matchUUID: String, token: String) async throws -> RegisterPushTokenResponse {
        let deviceId = keychain.getDeviceId()
        let environment: String
        #if DEBUG
        environment = "development"
        #else
        environment = "production"
        #endif

        let request = RegisterPushTokenRequest(
            token: token,
            deviceId: deviceId,
            type: "match",
            matchId: matchUUID,
            environment: environment
        )

        return try await self.request(
            endpoint: "/push-tokens/register",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }
}

// MARK: - Debug Extension

#if DEBUG
extension SHLAPIClient {
    /// Test push notifications (Debug Only)
    /// Uses JWT authentication to identify the user automatically
    public func testNotification(request: TestNotificationRequest) async throws -> TestNotificationResponse {
        print("\n========== TEST NOTIFICATION REQUEST ==========")
        print("URL: \(baseURL)/api/v1/test-notification")
        print("Method: POST")

        if let requestData = try? JSONEncoder().encode(request),
           let requestJSON = String(data: requestData, encoding: .utf8) {
            print("Request Body: \(requestJSON)")
        }

        if let token = keychain.getToken() {
            let tokenPreview = String(token.prefix(10)) + "..." + String(token.suffix(10))
            print("JWT Token: \(tokenPreview)")
        }

        print("================================================\n")

        do {
            let response: TestNotificationResponse = try await self.request(
                endpoint: "/test-notification",
                method: .post,
                body: request,
                requiresAuth: true
            )
            print("Test notification sent successfully")
            return response
        } catch {
            print("Test notification failed: \(error)")
            throw error
        }
    }
}
#endif
