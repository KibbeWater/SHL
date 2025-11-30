//
//  HomeViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    @Published var featuredGame: Match? = nil
    @Published var liveGame: LiveMatch? = nil
    @Published var latestMatches: [Match] = []
    @Published var standings: [StandingObj]? = nil
    @Published var standingsDisabled: Bool = false

    private var liveGameExternalId: String?
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
        liveGameExternalId = game.externalUUID
        listenForLiveGame()
    }

    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }

        cancellable = liveListener.subscribe() { [weak self] gameUuid in
            guard let self = self else { return nil }
            guard let liveGameExternalId = self.liveGameExternalId, gameUuid == liveGameExternalId else { return nil }
            guard let match = self.latestMatches.first(where: { $0.externalUUID == gameUuid }) else { return nil }

            // Fetch team data
            return await self.fetchTeamData(for: match)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] liveMatch in
            self?.liveGame = liveMatch
        }

        if let liveGameExternalId {
            liveListener.requestInitialData([liveGameExternalId])
        }
    }

    private func fetchTeamData(for match: Match) async -> (match: Match, homeTeam: Team, awayTeam: Team)? {
        guard let homeId = match.homeTeam.id, let awayId = match.awayTeam.id else { return nil }

        async let homeTeam = try? await api.getTeamDetail(id: homeId)
        async let awayTeam = try? await api.getTeamDetail(id: awayId)

        guard let home = await homeTeam, let away = await awayTeam else { return nil }
        return (match: match, homeTeam: home, awayTeam: away)
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

    func SelectFeaturedMatch() async throws {
        guard let recent = try? await api.getRecentMatches() else { return }
        let matches = recent.upcoming + recent.recent

        featuredGame = await FeaturedGameAlgo.getFeaturedGame(
            matches,
            interestedTeams: Settings.shared.getInterestedTeamIds()
        )
    }
}
