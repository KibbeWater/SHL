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

    @Published var liveGame: LiveMatch? = nil
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
