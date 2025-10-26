//
//  MatchViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Combine
import Foundation
import HockeyKit
import SwiftUI

@MainActor
class MatchViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    @Published var match: Match? = nil
    @Published var matchStats: [MatchStats] = []
    @Published var pbp: PBPEventsAdapter? = nil

    @Published var home: Team? = nil
    @Published var away: Team? = nil

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
        if hard {}

        match = try await api.getMatchDetail(id: game.id)

        if let match {
            try await fetchTeam(match)
            if match.isLive(), let live = try? await api.getLiveExternal(id: match.externalUUID) {
                liveGame = live
            }
        }

        matchStats = (try? await api.getMatchStats(id: game.id)) ?? []

        try await refreshPBP()
    }

    func refreshPBP() async throws {
        let backendEvents = try await api.getMatchEvents(id: game.id)
        // Use the current match if available, otherwise use the initial game
        let matchForMapping = match ?? game
        pbp = PBPEventsAdapter.from(backendEvents: backendEvents, match: matchForMapping)
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

        cancellable = liveListener.subscribe([game.externalUUID])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if self?.game.externalUUID == event.gameOverview.gameUuid {
                    self?.liveGame = event
                }
            }
    }
}
