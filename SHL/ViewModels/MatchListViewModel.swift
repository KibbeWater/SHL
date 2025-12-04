//
//  MatchListViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class MatchListViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    @Published var latestMatches: [Match] = []
    @Published var previousMatches: [Match] = []
    @Published var todayMatches: [Match] = []
    @Published var upcomingMatches: [Match] = []

    @Published var matchListeners: [String: LiveMatch] = [:]
    private var cancellable: AnyCancellable?

    init() {
        Task {
            try? await refresh()
            // Note: listenForLiveGame() is called at the end of refresh()
            // so todayMatches is populated before subscribing
        }
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
            // Fetch initial live data from API for immediate display
            await fetchInitialLiveData()
            // Subscribe with updated todayMatches for live updates
            listenForLiveGame()
        }
    }

    /// Fetch initial live data from API for all today's matches
    /// This provides instant data without waiting for SSE cache
    private func fetchInitialLiveData() async {
        for match in todayMatches {
            if let live = try? await api.getLiveMatch(id: match.externalUUID) {
                matchListeners[live.externalId] = live
            }
        }
    }

    private func removeUnusedListeners() {
        var newListeners: [String: LiveMatch] = [:]
        for game in todayMatches {
            guard let listenerData = matchListeners[game.externalUUID] else { continue }
            newListeners[game.externalUUID] = listenerData
        }
        matchListeners = newListeners
    }

    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }

        cancellable = liveListener.subscribe(todayMatches.map { $0.externalUUID }) { [weak self] gameUuid in
            guard let self = self else { return nil }
            guard let match = self.todayMatches.first(where: { $0.externalUUID == gameUuid }) else { return nil }

            // Fetch team data
            return await self.fetchTeamData(for: match)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] liveMatch in
            self?.matchListeners[liveMatch.externalId] = liveMatch
        }
    }

    private func fetchTeamData(for match: Match) async -> (match: Match, homeTeam: Team, awayTeam: Team)? {
        guard let homeId = match.homeTeam.id, let awayId = match.awayTeam.id else { return nil }

        async let homeTeam = try? await api.getTeamDetail(id: homeId)
        async let awayTeam = try? await api.getTeamDetail(id: awayId)

        guard let home = await homeTeam, let away = await awayTeam else { return nil }
        return (match: match, homeTeam: home, awayTeam: away)
    }

    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current

        previousMatches = latestMatches.filter { $0.date < calendar.startOfDay(for: now) }.sorted(by: { $0.date > $1.date }).map { $0 }
        todayMatches = latestMatches.filter { calendar.isDateInToday($0.date) }.map { $0 }
        upcomingMatches = latestMatches.filter { calendar.startOfDay(for: $0.date) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }.map { $0 }
    }
}
