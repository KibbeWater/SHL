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
        try await request(.latestMatches)
    }

    func getMatchDetail(id: String) async throws -> MatchDetail {
        try await request(.matchDetail(id: id))
    }

    func getMatchStats(id: String) async throws -> MatchStats {
        try await request(.matchStats(id: id))
    }

    func getMatchPBP(id: String) async throws -> PBPEvents {
        try await request(.matchPBP(id: id))
    }

    func getSchedule(seasonId: String, seriesId: String, teamIds: [String]? = nil) async throws -> [Match] {
        try await request(.schedule(seasonId: seasonId, seriesId: seriesId, teamIds: teamIds))
    }

    // MARK: - Team Endpoints

    func getTeams() async throws -> [Team] {
        try await request(.teams)
    }

    func getTeamDetail(id: String) async throws -> TeamDetail {
        try await request(.teamDetail(id: id))
    }

    func getTeamLineup(id: String) async throws -> TeamLineup {
        try await request(.teamLineup(id: id))
    }

    // MARK: - Player Endpoints

    func getPlayerDetail(id: String) async throws -> Player {
        try await request(.playerDetail(id: id))
    }

    func getPlayerGameLog(id: String) async throws -> [PlayerGameLog] {
        try await request(.playerGameLog(id: id))
    }

    // MARK: - Season/League Endpoints

    func getCurrentSeason() async throws -> Season {
        try await request(.currentSeason)
    }

    func getCurrentSsgt() async throws -> String {
        let response: SsgtResponse = try await request(.currentSsgt)
        return response.ssgtUuid
    }

    func getStandings(ssgtUuid: String) async throws -> Standings {
        try await request(.standings(ssgtUuid: ssgtUuid))
    }

    func getCurrentSeries() async throws -> Series {
        try await request(.currentSeries)
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
                case .success(let response):
                    do {
                        // Check status code
                        guard (200..<300).contains(response.statusCode) else {
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

                case .failure(let error):
                    continuation.resume(throwing: SHLAPIError.networkError(underlying: error))
                }
            }
        }
    }
}

// MARK: - Helper Response Types

private struct SsgtResponse: Codable {
    let ssgtUuid: String
}
