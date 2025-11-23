//
//  MatchViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class MatchViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    @Published var match: Match? = nil
    @Published var matchStats: [MatchStats] = []
    @Published var pbpController: PBPController? = nil

    @Published var home: Team? = nil
    @Published var away: Team? = nil

    @Published var liveGame: LiveMatch? = nil
    private var cancellable: AnyCancellable?

    private var game: Match

    /// Get PBP events sorted with period markers based on game state
    /// - Completed games: chronological order (Period 1 → 2 → 3)
    /// - Live games: reverse chronological order (Period 3 → 2 → 1)
    var sortedPBPEvents: [PBPEventDTO] {
        guard let controller = pbpController else { return [] }
        return controller.sortedWithPeriodMarkers(reverse: liveGame != nil)
    }

    init(_ game: Match) {
        self.game = game

        Task {
            try? await refresh()
        }

        listenForLiveGame()
    }

    deinit {
        cancellable?.cancel()
    }

    func refresh(hard: Bool = false) async throws {
        if hard {}

        match = try await api.getMatchDetail(id: game.id)
        
        if let match {
            if let live = try? await api.getLiveMatch(id: match.externalUUID) {
                self.liveGame = live
            }
            try await fetchTeam(match)
        }

        matchStats = (try? await api.getMatchStats(id: game.id)) ?? []

        try await refreshPBP()
    }

    func refreshPBP() async throws {
        pbpController = try await api.getMatchPBPController(id: game.id)
    }

    func fetchTeam(_ matchDetail: Match) async throws {
        if let homeId = matchDetail.homeTeam.id {
            home = try? await api.getTeamDetail(id: homeId)
        }

        if let awayId = matchDetail.awayTeam.id {
            away = try? await api.getTeamDetail(id: awayId)
        }
    }

    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }

        cancellable = liveListener.subscribe([game.externalUUID]) { [weak self] gameUuid in
            guard let self = self else { return nil }
            guard let match = self.match, match.externalUUID == gameUuid else { return nil }
            guard let home = self.home, let away = self.away else { return nil }

            return (match: match, homeTeam: home, awayTeam: away)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] liveMatch in
            self?.liveGame = liveMatch
        }
    }
}
