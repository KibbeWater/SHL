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
    @Published var calendarLiveMatches: [String: LiveMatch] = [:]

    private var liveGameExternalId: String?
    private var cancellable: AnyCancellable?
    private var calendarCancellable: AnyCancellable?
    private var pollingTimer: Timer?

    init() {
        Task {
            try? await refresh()
        }
    }

    deinit {
        cancellable?.cancel()
        calendarCancellable?.cancel()
        pollingTimer?.invalidate()
    }

    func selectListenedGame(_ game: Match) {
        liveGameExternalId = game.externalUUID
        Task {
            await fetchInitialLiveData(for: game)
        }
        listenForLiveGame()
        startPollingIfNeeded()
    }

    /// Fetch initial live data from API for immediate display
    /// This provides instant data without waiting for SSE cache
    private func fetchInitialLiveData(for game: Match) async {
        do {
            let live = try await api.getLiveMatch(id: game.externalUUID)
            if live.gameState == .played {
                self.liveGame = nil
            } else {
                self.liveGame = live
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch live data for featured game \(game.id): \(error)")
            #endif
        }
    }

    /// Poll for live match data periodically as a fallback when SSE is unavailable
    private func startPollingIfNeeded() {
        pollingTimer?.invalidate()
        pollingTimer = nil

        guard featuredGame != nil else { return }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let featured = self.featuredGame else { return }
                await self.fetchInitialLiveData(for: featured)
            }
        }
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
            if liveMatch.gameState == .played {
                self?.liveGame = nil
            } else {
                self?.liveGame = liveMatch
            }
        }
    }

    private func listenForCalendarMatches() {
        calendarCancellable?.cancel()

        let calendarMatchIds = latestMatches
            .filter { !$0.played && Calendar.current.isDateInToday($0.date) }
            .map { $0.externalUUID }

        guard !calendarMatchIds.isEmpty else { return }

        calendarCancellable = liveListener.subscribe(calendarMatchIds) { [weak self] gameUuid in
            guard let self = self else { return nil }
            guard let match = self.latestMatches.first(where: { $0.externalUUID == gameUuid }) else { return nil }
            return await self.fetchTeamData(for: match)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] liveMatch in
            if liveMatch.gameState == .played {
                self?.calendarLiveMatches.removeValue(forKey: liveMatch.externalId)
            } else {
                self?.calendarLiveMatches[liveMatch.externalId] = liveMatch
            }
        }
    }

    private func fetchInitialCalendarData() async {
        let calendarMatches = latestMatches
            .filter { !$0.played && Calendar.current.isDateInToday($0.date) }

        for match in calendarMatches {
            do {
                let live = try await api.getLiveMatch(id: match.externalUUID)
                if live.gameState == .played {
                    calendarLiveMatches.removeValue(forKey: live.externalId)
                } else {
                    calendarLiveMatches[live.externalId] = live
                }
            } catch {
                // Match not live yet - expected 404
            }
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

        // Refresh live data for featured game
        if let featured = featuredGame {
            liveGameExternalId = featured.externalUUID
            await fetchInitialLiveData(for: featured)
        }
        listenForLiveGame()
        startPollingIfNeeded()

        // Refresh live data for calendar matches
        await fetchInitialCalendarData()
        listenForCalendarMatches()

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
            let gd = standing.goalDifference
            let diffStr = gd > 0 ? "+\(gd)" : String(gd)
            return StandingObj(
                id: standing.id,
                teamId: standing.team.id,
                position: standing.rank,
                team: standing.team.name,
                teamCode: standing.team.code,
                gamesPlayed: standing.gamesPlayed,
                wins: standing.wins,
                overtimeWins: standing.overtimeWins,
                losses: standing.losses,
                overtimeLosses: standing.overtimeLosses,
                diff: diffStr,
                points: String(standing.points),
                teamObj: standing.team
            )
        }
    }

    // MARK: - Calculate featured game by relevance

    func SelectFeaturedMatch() async throws {
        guard let recent = try? await api.getRecentMatches() else { return }
        let matches = recent.upcoming + recent.recent

        // Fetch currently live matches to ensure the algo prioritizes them
        // even if the static Match.state hasn't updated yet
        let liveMatches = (try? await api.getLiveMatches()) ?? []
        let liveUUIDs = Set(liveMatches.map { $0.externalUUID })

        featuredGame = await FeaturedGameAlgo.getFeaturedGame(
            matches,
            interestedTeams: Settings.shared.getInterestedTeamIds(),
            favoriteTeamId: Settings.shared.getFavoriteTeamId(),
            liveExternalUUIDs: liveUUIDs
        )
    }
}
