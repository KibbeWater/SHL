//
//  SHLAPIClient.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
import Moya

class SHLAPIClient {
    static let shared = SHLAPIClient()

    private let provider: MoyaProvider<SHLAPIService>
    private let decoder: JSONDecoder
    private let keychain = KeychainManager.shared

    private init() {
        // Configure decoder
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Configure provider with plugins
        #if DEBUG
            let plugins: [PluginType] = [NetworkLoggerPlugin(verbose: true)]
        #else
            let plugins: [PluginType] = []
        #endif

        provider = MoyaProvider<SHLAPIService>(plugins: plugins)
    }

    // MARK: - Match Endpoints

    func getLatestMatches() async throws -> [Match] {
        let response: PaginatedResponse<Match> = try await request(.latestMatches(page: 1, limit: 20))
        return response.data
    }

    /// Search matches with optional filters and pagination
    /// - Parameters:
    ///   - date: Optional ISO8601 date string to filter by specific date
    ///   - team: Optional team code to filter by team (home or away)
    ///   - season: Optional season code to filter by season
    ///   - state: Optional match state (scheduled, ongoing, paused, played)
    ///   - page: Page number for pagination (default: 1)
    ///   - limit: Number of results per page (default: 20)
    /// - Returns: Paginated response containing matches and pagination metadata
    func searchMatches(
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

    func getLiveMatches() async throws -> [Match] {
        try await request(.liveMatches)
    }

    func getLiveMatch(id: String) async throws -> LiveMatch {
        try await request(.getLiveMatch(id: id))
    }

    func getMatchDetail(id: String) async throws -> Match {
        try await request(.matchDetail(id: id))
    }

    func getMatchStats(id: String) async throws -> [MatchStats] {
        try await request(.matchStats(id: id))
    }

    /// Get match events as rich DTOs
    func getMatchEvents(id: String) async throws -> [PBPEventDTO] {
        try await request(.matchEvents(id: id))
    }

    /// Get match events wrapped in a PBPController for easy manipulation
    func getMatchPBPController(id: String) async throws -> PBPController {
        let events: [PBPEventDTO] = try await request(.matchEvents(id: id))

        // Deduplicate events by ID (API may return duplicates)
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

    func getSeasonMatches(seasonCode: String) async throws -> [Match] {
        try await request(.seasonMatches(seasonCode: seasonCode))
    }

    func getRecentMatches(limit: Int = 10) async throws -> RecentMatchesResponse {
        try await request(.recentMatches(limit: limit))
    }

    // MARK: - Team Endpoints

    func getTeams() async throws -> [Team] {
        try await request(.teams)
    }

    func getTeamDetail(id: String) async throws -> Team {
        try await request(.teamDetail(id: id))
    }

    func getTeamRoster(id: String) async throws -> [Player] {
        try await request(.teamRoster(id: id))
    }

    func getTeamMatches(id: String) async throws -> [Match] {
        try await request(.teamMatches(id: id))
    }

    // MARK: - Player Endpoints

    func getPlayerDetail(id: String) async throws -> Player {
        try await request(.playerDetail(id: id))
    }

    func getPlayerStats(id: String) async throws -> [PlayerGameLog] {
        try await request(.playerStats(id: id))
    }

    // MARK: - Season/League Endpoints

    func getCurrentSeason() async throws -> Season {
        try await request(.currentSeason)
    }

    func getCurrentSeasonInfo() async throws -> SeasonInfoResponse {
        try await request(.currentSeasonInfo)
    }

    func getAllSeasons() async throws -> [Season] {
        try await request(.allSeasons)
    }

    func getStandings(seasonId: String) async throws -> [Standings] {
        try await request(.standings(seasonId: seasonId))
    }

    func getCurrentStandings() async throws -> [Standings] {
        try await request(.currentStandings)
    }

    // MARK: - User Management Endpoints

    /// Generic authenticated request with automatic token refresh
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]

        // Add JWT token if required
        if requiresAuth {
            guard let token = keychain.getToken() else {
                throw SHLAPIError.unauthorized
            }
            headers["Authorization"] = "Bearer \(token)"
        }

        // Build URL
        guard let url = URL(string: "https://api.lrlnet.se/api/v1\(endpoint)") else {
            throw SHLAPIError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Add body if present
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SHLAPIError.invalidResponse
        }

        // Handle 401 Unauthorized - token expired
        if httpResponse.statusCode == 401 && requiresAuth {
            // Try to refresh token
            do {
                try await AuthenticationManager.shared.refreshToken()
                // Retry request with new token
                return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
            } catch {
                throw SHLAPIError.unauthorized
            }
        }

        // Check status code
        #if DEBUG
        print("\n========== API RESPONSE ==========")
        print("Status Code: \(httpResponse.statusCode)")
        print("URL: \(httpResponse.url?.absoluteString ?? "unknown")")

        if !(200..<300).contains(httpResponse.statusCode) {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error Response Body: \(errorString)")
            }
        }
        print("==================================\n")
        #endif

        guard (200..<300).contains(httpResponse.statusCode) else {
            let error = SHLAPIError.map(statusCode: httpResponse.statusCode, data: data)
            throw error
        }

        // Handle empty response for 201 Created (common for resource creation)
        if httpResponse.statusCode == 201 && data.isEmpty {
            if T.self == RegisterPushTokenResponse.self {
                // Return a success response with default values
                return RegisterPushTokenResponse(success: true, message: nil) as! T
            } else if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }

        // Handle empty response for 204 No Content
        if httpResponse.statusCode == 204 {
            // Return empty response for Void type
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw SHLAPIError.decodingError(underlying: decodingError)
        }
    }

    /// Update notification settings
    func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettingsResponse {
        try await request(
            endpoint: "/user/notifications",
            method: .patch,
            body: settings,
            requiresAuth: true
        )
    }

    /// Set favorite team
    func setFavoriteTeam(teamId: String) async throws -> FavoriteTeamResponse {
        try await request(
            endpoint: "/user/favorite-team",
            method: .put,
            body: FavoriteTeamRequest(teamId: teamId),
            requiresAuth: true
        )
    }

    /// Remove favorite team
    func removeFavoriteTeam() async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/user/favorite-team",
            method: .delete,
            requiresAuth: true
        )
    }

    /// Register push notification token
    func registerPushToken(_ request: RegisterPushTokenRequest) async throws -> RegisterPushTokenResponse {
        try await self.request(
            endpoint: "/push-tokens/register",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }

    /// Get all devices
    func getDevices() async throws -> DevicesResponse {
        try await request(
            endpoint: "/devices",
            method: .get,
            requiresAuth: true
        )
    }

    /// Update device name or notification settings
    func updateDevice(deviceId: String, name: String? = nil, notificationsEnabled: Bool? = nil) async throws {
        let request = UpdateDeviceRequest(deviceName: name, notificationsEnabled: notificationsEnabled)
        let _: EmptyResponse = try await self.request(
            endpoint: "/devices/\(deviceId)",
            method: .put,
            body: request,
            requiresAuth: true
        )
    }

    /// Remove device
    func removeDevice(deviceId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/devices/\(deviceId)",
            method: .delete,
            requiresAuth: true
        )
    }

    /// Get all push tokens
    func getPushTokens() async throws -> PushTokensResponse {
        try await request(
            endpoint: "/push-tokens",
            method: .get,
            requiresAuth: true
        )
    }

    /// Delete push token
    func deletePushToken(tokenId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/push-tokens/\(tokenId)",
            method: .delete,
            requiresAuth: true
        )
    }

    /// Register push token for live match
    func registerLiveActivityToken(matchUUID: String, token: String) async throws -> RegisterPushTokenResponse {
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
            environment: environment
        )

        return try await self.request(
            endpoint: "/live/\(matchUUID)",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }

    // MARK: - Private Helper Methods

    private func request<T: Decodable>(_ target: SHLAPIService) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: SHLAPIError.unknown)
                    return
                }

                switch result {
                case let .success(response):
                    do {
                        // Check status code
                        guard (200 ..< 300).contains(response.statusCode) else {
                            let error = SHLAPIError.map(statusCode: response.statusCode, data: response.data)
                            continuation.resume(throwing: error)
                            return
                        }

                        // Decode response
                        let decoded = try self.decoder.decode(T.self, from: response.data)
                        continuation.resume(returning: decoded)
                    } catch let decodingError as DecodingError {
                        continuation.resume(throwing: SHLAPIError.decodingError(underlying: decodingError))
                    } catch {
                        continuation.resume(throwing: SHLAPIError.invalidResponse)
                    }

                case let .failure(error):
                    continuation.resume(throwing: SHLAPIError.networkError(underlying: error))
                }
            }
        }
    }
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Empty Response for 204 No Content

struct EmptyResponse: Codable {
    init() {}
}

// MARK: - Helper Response Types

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let page: Int
    let limit: Int
    let total: Int
}
