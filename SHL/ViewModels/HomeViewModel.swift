//
//  HomeViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Combine
import Foundation
import HockeyKit
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    @Published var featuredGame: Match? = nil
    @Published var liveGame: GameData? = nil
    @Published var latestMatches: [Match] = []
    @Published var standings: [StandingObj]? = nil
    @Published var standingsDisabled: Bool = false

    private var liveGameId: String?
    private var cancellable: AnyCancellable?

    init() {
        Task {
            try? await refresh()
        }

        listenForLiveGame()
    }

    deinit {
        cancellable?.cancel()
    }

    func selectListenedGame(_ game: Match) {
        liveGameId = game.id
        listenForLiveGame()
    }

    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }

        cancellable = liveListener.subscribe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if event.gameOverview.gameUuid == self?.liveGameId {
                    self?.liveGame = event
                }
            }

        if let liveGameId {
            liveListener.requestInitialData([liveGameId])
        }
    }

    func refresh(hard: Bool = false) async throws {
        if hard {}

        try await SelectFeaturedMatch()
        let recentMatches = try await api.getRecentMatches()
        latestMatches = recentMatches.upcoming + recentMatches.recent

        do {
            let _standings = try await api.getCurrentStandings()
            standings = formatStandings(_standings)
            standingsDisabled = false
        } catch let error as SHLAPIError {
            if case .networkError = error {
                standingsDisabled = true
            } else {
                throw error
            }
        }
    }

    func formatStandings(_ standings: [Standings]) -> [StandingObj] {
        return standings.map { standing in
            StandingObj(
                id: standing.id,
                position: standing.rank,
                team: standing.team.name,
                teamCode: standing.team.code,
                matches: String(standing.gamesPlayed),
                diff: String(standing.goalDifference),
                points: String(standing.points)
            )
        }
    }

    // MARK: - Calculate featured game by relevance

    // TODO: Use FeaturedGameAlgo functions instead

    func SelectFeaturedMatch() async throws {
        guard let recent = try? await api.getRecentMatches() else { return }
        let matches = recent.upcoming + recent.recent

        let scoredMatches = await scoreAndSortHockeyMatches(
            matches,
            preferredTeam: Settings.shared.getPreferredTeam()
        )

        featuredGame = scoredMatches.first?.0
    }

    func getTeamByCode(_ code: String) async -> Team? {
        guard let teams = try? await api.getTeams() else { return nil }
        return teams.first(where: { $0.code == code })
    }

    func scoreAndSortHockeyMatches(_ matches: [Match], preferredTeam: String?) async -> [(Match, Double)] {
        // First, asynchronously get all team UUIDs
        let teamUUIDs = await withTaskGroup(of: (String, String).self) { group in
            for match in matches {
                group.addTask {
                    let homeTeam = await self.getTeamByCode(match.homeTeam.code)
                    return (match.homeTeam.code, homeTeam?.id ?? "")
                }
                group.addTask {
                    let awayTeam = await self.getTeamByCode(match.awayTeam.code)
                    return (match.awayTeam.code, awayTeam?.id ?? "")
                }
            }

            var uuidDict = [String: String]()
            for await (code, uuid) in group {
                uuidDict[code] = uuid
            }
            return uuidDict
        }

        // Now score the matches
        let scoredMatches = matches.map { game -> (Match, Double) in
            var score: Double = 0

            // Live games get the highest base score
            if game.isLive() {
                score += 1000
            }

            // Preferred team bonus
            if let preferredTeam = preferredTeam,
               let homeTeamUUID = teamUUIDs[game.homeTeam.code],
               let awayTeamUUID = teamUUIDs[game.awayTeam.code]
            {
                if homeTeamUUID == preferredTeam || awayTeamUUID == preferredTeam {
                    score += 500
                }
            }

            // Upcoming games score
            if !game.played {
                let timeUntilGame = game.date.timeIntervalSinceNow
                if timeUntilGame > 0 {
                    score += max(100 - log10(timeUntilGame / 3600) * 20, 0)
                }
            } else {
                // Played games score
                let timeSinceGame = -game.date.timeIntervalSinceNow
                score += max(50 - log10(timeSinceGame / 3600) * 10, 0)
            }

            return (game, score)
        }

        // Sort the matches based on their scores, highest to lowest
        return scoredMatches.sorted { $0.1 > $1.1 }
    }
}
