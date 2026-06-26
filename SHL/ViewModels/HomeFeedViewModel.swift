//
//  HomeFeedViewModel.swift
//  SHL
//
//  Drives the redesigned home feed. Loads the single v2 `HomeSummary`
//  (`GET /api/v2/home`) and layers live SSE updates on top so in-progress games
//  show a ticking clock and live scores. Standings are projected into the shared
//  `StandingObj` the table component expects.
//

import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class HomeFeedViewModel {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared

    /// The whole home payload. `nil` until the first load resolves.
    private(set) var summary: HomeSummary?
    private(set) var isLoading = false
    /// True when the last load failed and we have nothing to show.
    private(set) var loadFailed = false

    /// Live data keyed by a game's external UUID, merged over the summary's games.
    var liveMatches: [String: LiveMatch] = [:]

    @ObservationIgnored private var cancellable: AnyCancellable?
    @ObservationIgnored private var pollTimer: Timer?

    // MARK: - Derived

    var liveGames: [Match] { summary?.live ?? [] }

    /// Live games other than the featured one (the featured shows as the hero).
    var secondaryLiveGames: [Match] {
        guard let featuredId = summary?.featured?.externalUUID else { return liveGames }
        return liveGames.filter { $0.externalUUID != featuredId }
    }

    /// The full table projected into the shared row model the table component uses.
    var standings: [StandingObj] { mapStandings(summary?.standings ?? []) }

    /// Last season's final table (the pre-season recap), same projection.
    var previousStandings: [StandingObj] { mapStandings(summary?.previousStandings ?? []) }

    /// Season lifecycle phase + its metadata, driving which home variant renders.
    var phase: SeasonPhase { summary?.phase ?? .regular }
    var seasonMeta: SeasonMeta? { summary?.season }
    var champion: ChampionInfo? { summary?.champion }

    private func mapStandings(_ rows: [Standings]) -> [StandingObj] {
        rows.map { s in
            let gd = s.goalDifference
            return StandingObj(
                id: s.id, teamId: s.team.id, position: s.rank, team: s.team.name,
                teamCode: s.team.code, gamesPlayed: s.gamesPlayed,
                wins: s.wins, overtimeWins: s.overtimeWins, losses: s.losses,
                overtimeLosses: s.overtimeLosses,
                diff: gd > 0 ? "+\(gd)" : String(gd), points: String(s.points), teamObj: s.team
            )
        }
    }

    /// Top `limit` rows, with the favorite team appended if it sits below the cut —
    /// so the snapshot always shows where the user's team stands.
    func standingsSnapshot(limit: Int = 6, favoriteId: String?) -> [StandingObj] {
        let all = standings
        var snapshot = Array(all.prefix(limit))
        if let favoriteId, !snapshot.contains(where: { $0.teamId == favoriteId }),
           let fav = all.first(where: { $0.teamId == favoriteId }) {
            snapshot.append(fav)
        }
        return snapshot
    }

    /// The favorite team's full `Team` (for navigation). Prefer the standings row
    /// (richest data); otherwise synthesize a minimal team from the favorite block
    /// so the hero still navigates — `TeamView` loads full detail from the id/code.
    var favoriteTeam: Team? {
        guard let fav = summary?.favorite else { return nil }
        if let resolved = (summary?.standings ?? []).first(where: {
            $0.team.id == fav.teamId || $0.team.code.caseInsensitiveCompare(fav.team.code) == .orderedSame
        })?.team {
            return resolved
        }
        return Team(
            id: fav.teamId ?? fav.team.id ?? fav.team.code, name: fav.team.name, code: fav.team.code,
            city: nil, founded: nil, venue: nil, golds: nil, goldYears: nil,
            finals: nil, finalYears: nil, iconURL: nil, isActive: true
        )
    }

    /// Live data for a given game, if any.
    func live(for match: Match) -> LiveMatch? { liveMatches[match.externalUUID] }

    // MARK: - Loading

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            summary = try await api.getHomeSummary(team: Settings.shared.getFavoriteTeam()?.code)
            loadFailed = false
            await refreshLiveData()
            subscribeLive()
            startPolling()
        } catch {
            // Use real data only — on failure keep any prior data and surface the
            // error/retry state when we have nothing to show.
            loadFailed = (summary == nil)
        }
    }

    func refresh() async {
        await load()
    }

    func stop() {
        cancellable?.cancel()
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// Preset with a payload for previews — bypasses the network entirely.
    func preload(_ summary: HomeSummary) {
        self.summary = summary
        self.loadFailed = false
    }

    /// A view model preloaded with mock data, for `#Preview`.
    static func preview(_ summary: HomeSummary = .mock) -> HomeFeedViewModel {
        let vm = HomeFeedViewModel()
        vm.preload(summary)
        return vm
    }

    // MARK: - Live wiring

    private func refreshLiveData() async {
        for game in liveGames {
            guard let live = try? await api.getLiveMatch(id: game.externalUUID) else { continue }
            if live.gameState == .played || live.gameState == .cancelled {
                liveMatches.removeValue(forKey: live.externalId)
            } else {
                liveMatches[live.externalId] = live
            }
        }
    }

    private func subscribeLive() {
        cancellable?.cancel()
        let ids = liveGames.map { $0.externalUUID }
        guard !ids.isEmpty else { return }

        cancellable = liveListener.subscribe(ids) { [weak self] gameUuid in
            guard let self else { return nil }
            guard let match = self.liveGames.first(where: { $0.externalUUID == gameUuid }) else { return nil }
            return await self.fetchTeamData(for: match)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] live in
            if live.gameState == .played || live.gameState == .cancelled {
                self?.liveMatches.removeValue(forKey: live.externalId)
            } else {
                self?.liveMatches[live.externalId] = live
            }
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        guard !liveGames.isEmpty else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refreshLiveData() }
        }
    }

    private func fetchTeamData(for match: Match) async -> (match: Match, homeTeam: Team, awayTeam: Team)? {
        guard let homeId = match.homeTeam.id, let awayId = match.awayTeam.id else { return nil }
        async let home = try? await api.getTeamDetail(id: homeId)
        async let away = try? await api.getTeamDetail(id: awayId)
        guard let h = await home, let a = await away else { return nil }
        return (match: match, homeTeam: h, awayTeam: a)
    }
}
