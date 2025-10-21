//
//  WidgetAPI.swift
//  SHLWidget
//
//  Simple API client for widget - uses direct URLSession calls
//

import Foundation

class WidgetAPI {
    private let baseURL: String
    private let decoder: JSONDecoder

    init() {
        // Use environment variable or default to production
        self.baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://api.lrlnet.se"

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func getLatestMatches() async throws -> [WidgetGame] {
        guard let url = URL(string: "\(baseURL)/matches/latest") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Backend returns array of matches
        let matches = try decoder.decode([BackendMatch].self, from: data)
        return matches.map { $0.toWidgetGame() }
    }
}

// Backend response models
private struct BackendMatch: Codable {
    let id: String
    let date: Date
    let venue: String?
    let homeTeam: BackendTeam
    let awayTeam: BackendTeam
    let homeScore: Int
    let awayScore: Int

    func toWidgetGame() -> WidgetGame {
        WidgetGame(
            id: id,
            date: date,
            venue: venue ?? "Unknown",
            homeTeam: WidgetTeam(name: homeTeam.name, code: homeTeam.code),
            awayTeam: WidgetTeam(name: awayTeam.name, code: awayTeam.code),
            homeScore: homeScore,
            awayScore: awayScore
        )
    }
}

private struct BackendTeam: Codable {
    let name: String
    let code: String
}
