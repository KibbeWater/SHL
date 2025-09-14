//
//  HomeViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Foundation
import HockeyKit
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private var api: HockeyAPI? = nil
    
    @Published var featuredGame: Game? = nil
    @Published var liveGame: GameData? = nil
    @Published var latestMatches: [Game] = []
    @Published var standings: [StandingObj]? = nil
    @Published var standingsDisabled: Bool = false
    
    private var liveGameId: String? = nil
    private var cancellable: AnyCancellable?
    
    deinit {
        cancellable?.cancel()
    }
    
    func setAPI(_ api: HockeyAPI) {
        self.api = api
        
        Task {
            try? await refresh()
        }
        
        listenForLiveGame()
    }

    func selectListenedGame(_ game: Game) {
        liveGameId = game.id
        listenForLiveGame()
    }
    
    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }
        
        
        cancellable = api?.listener.subscribe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if event.gameOverview.gameUuid == self?.liveGameId {
                    self?.liveGame = event
                }
            }
        
        if let liveGameId {
            api?.listener.requestInitialData([liveGameId])
        }
    }
    
    func refresh() async throws {
        try await SelectFeaturedMatch()
        latestMatches = try await api?.match.getLatest() ?? []
        
        if let ssgtUuid = try? await api?.season.getCurrentSsgt() {
            do {
                guard let _standings = try await api?.standings.getStandings(ssgtUuid: ssgtUuid) else {
                    standingsDisabled = true
                    return
                }
                standings = formatStandings(_standings)
                standingsDisabled = false
            } catch let error as HockeyAPIError {
                if case .networkError = error {
                    standingsDisabled = true
                } else {
                    throw error
                }
            }
        } else {
            standings = nil
            standingsDisabled = true
        }
    }
    
    func formatStandings(_ standings: Standings) -> [StandingObj] {
        return standings.leagueStandings.map({ standing in
            return StandingObj(
                id: UUID().uuidString,
                position: standing.Rank,
                logo: standing.info.teamInfo.teamMedia,
                team: standing.info.teamInfo.teamNames.long,
                teamCode: standing.info.id,
                matches: String(standing.GP),
                diff: String(standing.Diff),
                points: String(standing.Points)
            )
        })
    }
    
    // MARK: - Calculate featured game by relevance
    // TODO: Use FeaturedGameAlgo functions instead
    
    func SelectFeaturedMatch() async throws {
        guard let matches = try? await api?.match.getLatest() else { return }
        
        let scoredMatches = await scoreAndSortHockeyMatches(
            matches,
            preferredTeam: Settings.shared.getPreferredTeam()
        )
        
        featuredGame = scoredMatches.first?.0
    }
    
    func getTeamByCode(_ code: String) async -> SiteTeam? {
        guard let teams = try? await api?.team.getTeams() else { return nil }
        return teams.first(where: { $0.teamNames.code == code })
    }
    
    func scoreAndSortHockeyMatches(_ matches: [Game], preferredTeam: String?) async -> [(Game, Double)] {
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
        let scoredMatches = matches.map { game -> (Game, Double) in
            var score: Double = 0
            
            // Live games get the highest base score
            if game.isLive() {
                score += 1000
            }
            
            // Preferred team bonus
            if let preferredTeam = preferredTeam,
               let homeTeamUUID = teamUUIDs[game.homeTeam.code],
               let awayTeamUUID = teamUUIDs[game.awayTeam.code] {
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
