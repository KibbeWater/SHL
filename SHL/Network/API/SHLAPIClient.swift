//
//  SHLAPIClient.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
import HockeyKit
import Moya

class SHLAPIClient {
    static let shared = SHLAPIClient()

    private let provider: MoyaProvider<SHLAPIService>
    private let decoder: JSONDecoder

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

    func getLiveMatches() async throws -> [Match] {
        try await request(.liveMatches)
    }
    
    func getLiveMatch(id: String) async throws -> LiveMatch {
        try await request(.getLiveMatch(id: id))
    }
    
    func getLiveExternal(id: String) async throws -> HockeyKit.GameData {
        let data: GameDataResponse = try await request(.getLiveExternal(id: id))
        return data.data
    }

    func getMatchDetail(id: String) async throws -> Match {
        try await request(.matchDetail(id: id))
    }

    func getMatchStats(id: String) async throws -> [MatchStats] {
        try await request(.matchStats(id: id))
    }

    func getMatchEvents(id: String) async throws -> [PBPEvent] {
        try await request(.matchEvents(id: id))
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

    func getAllSeasons() async throws -> [Season] {
        try await request(.allSeasons)
    }

    func getStandings(seasonId: String) async throws -> [Standings] {
        try await request(.standings(seasonId: seasonId))
    }

    func getCurrentStandings() async throws -> [Standings] {
        try await request(.currentStandings)
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

// MARK: - Helper Response Types

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let page: Int
    let limit: Int
    let total: Int
}
