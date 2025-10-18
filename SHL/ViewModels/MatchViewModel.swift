//
//  MatchViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit
import Combine
import SwiftUI

@MainActor
class MatchViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener()

    @Published var match: MatchDetail? = nil
    @Published var matchStats: MatchStats? = nil
    @Published var pbp: PBPEvents? = nil

    @Published var home: TeamDetail? = nil
    @Published var away: TeamDetail? = nil

    @Published var liveGame: GameData? = nil
    private var cancellable: AnyCancellable?

    private var game: Match

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
        if hard {
        }

        match = try await api.getMatchDetail(id: game.id)
        matchStats = try? await api.getMatchStats(id: game.id)

        if let match {
            try await fetchTeam(match)
        }

        try await refreshPBP()
    }

    func refreshPBP() async throws {
        pbp = try await api.getMatchPBP(id: game.id)
    }

    func fetchTeam(_ matchDetail: MatchDetail) async throws {
        home = try? await api.getTeamDetail(id: matchDetail.homeTeam.uuid)
        away = try? await api.getTeamDetail(id: matchDetail.awayTeam.uuid)
    }

    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }

        cancellable = liveListener.subscribe([self.game.id])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if self?.game.id == event.gameOverview.gameUuid {
                    self?.liveGame = event
                }
            }
    }
}
