//
//  MatchListViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Combine
import Foundation
import HockeyKit
import SwiftUI

@MainActor
class MatchListViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    @Published var latestMatches: [Match] = []
    @Published var previousMatches: [Match] = []
    @Published var todayMatches: [Match] = []
    @Published var upcomingMatches: [Match] = []

    @Published var matchListeners: [String: GameData] = [:]
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

    func refresh(hard: Bool = false) async throws {
        if hard {}

        if let season = try? await api.getCurrentSeason() {
            latestMatches = (try? await api.getSeasonMatches(seasonCode: season.code)) ?? []

            filterMatches()
            removeUnusedListeners()
            liveListener.requestInitialData(todayMatches.filter { $0.isLive() || $0.played }.map { $0.id })
        }
    }

    private func removeUnusedListeners() {
        var newListeners: [String: GameData] = [:]
        for game in todayMatches {
            guard let listenerData = matchListeners[game.id] else { continue }
            newListeners[game.id] = listenerData
        }
        matchListeners = newListeners
    }

    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }

        cancellable = liveListener.subscribe(todayMatches.map { $0.externalUUID })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if self?.todayMatches.contains(where: { $0.externalUUID == event.gameOverview.gameUuid }) == true {
                    self?.matchListeners[event.gameOverview.gameUuid] = event
                }
            }
    }

    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current

        previousMatches = latestMatches.filter { $0.date < calendar.startOfDay(for: now) }.sorted(by: { $0.date > $1.date }).map { $0 }
        todayMatches = latestMatches.filter { calendar.isDateInToday($0.date) }.map { $0 }
        upcomingMatches = latestMatches.filter { calendar.startOfDay(for: $0.date) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }.map { $0 }
    }
}
