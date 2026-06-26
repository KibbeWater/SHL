//
//  ScheduleViewModel.swift
//  SHL
//
//  Drives the redesigned, date-navigated Schedule. Instead of pulling the whole
//  season at once, it loads only the *visible week* on demand — preferring the v2
//  range endpoint (`GET /api/v2/schedule?from=&to=&team=`) and falling back to
//  per-day `searchMatches` until that ships. Results are cached per week + team
//  filter, so flipping between days in a week is instant and changing weeks is one
//  fetch. Live SSE data is layered onto today's games when today is in view.
//

import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class ScheduleViewModel {
    private let api = SHLAPIClient.shared
    private let liveListener = LiveMatchListener.shared
    private let calendar = Calendar.current

    /// The day whose games are shown below the strip.
    private(set) var selectedDate: Date
    /// Monday (locale-dependent) of the visible week.
    private(set) var weekStart: Date
    /// Optional team-code filter ("FHC"); nil = all teams.
    private(set) var teamFilter: String?

    /// Matches for the visible week, keyed by start-of-day.
    private(set) var matchesByDay: [Date: [Match]] = [:]
    private(set) var isLoading = false

    /// Live data keyed by external UUID, layered over today's games.
    var liveMatches: [String: LiveMatch] = [:]
    /// All teams, for the filter menu.
    private(set) var teams: [Team] = []
    /// Dates ("yyyy-MM-dd") that have games, from the compound response — lets the
    /// week strip dot days in weeks that haven't been loaded yet.
    private(set) var gameDayKeys: Set<String> = []

    @ObservationIgnored private var cancellable: AnyCancellable?
    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var weekCache: [String: [Date: [Match]]] = [:]
    @ObservationIgnored private var serverNextScheduled: Date?

    init(date: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        self.selectedDate = today
        self.weekStart = Self.startOfWeek(for: today, calendar: cal)
    }

    // MARK: - Derived

    var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    func games(on date: Date) -> [Match] {
        (matchesByDay[calendar.startOfDay(for: date)] ?? []).sorted { $0.date < $1.date }
    }

    func hasGames(on date: Date) -> Bool {
        if !(matchesByDay[calendar.startOfDay(for: date)] ?? []).isEmpty { return true }
        return gameDayKeys.contains(Self.iso(date))
    }

    var selectedGames: [Match] { games(on: selectedDate) }

    func isToday(_ date: Date) -> Bool { calendar.isDateInToday(date) }
    func isSelected(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: selectedDate) }

    func live(for match: Match) -> LiveMatch? { liveMatches[match.externalUUID] }

    func isLive(_ match: Match) -> Bool {
        if let l = liveMatches[match.externalUUID] {
            return l.gameState == .ongoing || l.gameState == .paused
        }
        return match.isLive()
    }

    /// Live games among the selected day's slate (only meaningful for today).
    var liveSelectedGames: [Match] {
        guard calendar.isDateInToday(selectedDate) else { return [] }
        return selectedGames.filter { isLive($0) }
    }

    private var todayVisibleGames: [Match] {
        weekDays.filter { calendar.isDateInToday($0) }.flatMap { games(on: $0) }
    }

    var monthYearLabel: String {
        Self.monthFormatter.string(from: weekStart)
    }

    // MARK: - Navigation

    func loadInitial() async {
        // The compound response may also fill teams / live / gameDays / nextScheduled.
        await loadWeek()
        if teams.isEmpty { teams = (try? await api.getTeams()) ?? [] }
        // If today has nothing on, jump to the soonest day that has a scheduled game —
        // using the next game from the compound response, or a lookup as a fallback.
        if !hasGames(on: selectedDate) {
            var next = serverNextScheduled
            if next == nil { next = await firstScheduledGameDate() }
            if let next {
                selectedDate = calendar.startOfDay(for: next)
                let ws = Self.startOfWeek(for: selectedDate, calendar: calendar)
                if ws != weekStart {
                    weekStart = ws
                    await loadWeek()
                }
            }
        }
    }

    /// The day of the soonest upcoming scheduled game (v1 fallback for when the
    /// compound response didn't include `nextScheduled`).
    private func firstScheduledGameDate() async -> Date? {
        guard let resp = try? await api.searchMatches(state: "scheduled", descending: false, page: 1, limit: 1),
              let match = resp.data.first else { return nil }
        return calendar.startOfDay(for: match.date)
    }

    func select(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        selectedDate = day
        let ws = Self.startOfWeek(for: day, calendar: calendar)
        if ws != weekStart {
            weekStart = ws
            Task { await loadWeek() }
        }
    }

    func goToToday() { select(Date()) }

    func changeWeek(by weeks: Int) {
        guard let ws = calendar.date(byAdding: .weekOfYear, value: weeks, to: weekStart) else { return }
        // Keep the selected weekday when paging weeks.
        let weekdayOffset = calendar.dateComponents([.day], from: weekStart, to: selectedDate).day ?? 0
        weekStart = ws
        selectedDate = calendar.date(byAdding: .day, value: weekdayOffset, to: ws) ?? ws
        Task { await loadWeek() }
    }

    func setTeamFilter(_ code: String?) {
        guard teamFilter != code else { return }
        teamFilter = code
        weekCache.removeAll()
        Task { await loadWeek(force: true) }
    }

    // MARK: - Loading

    func loadWeek(force: Bool = false) async {
        let key = "\(Self.iso(weekStart))|\(teamFilter ?? "all")"
        if !force, let cached = weekCache[key] {
            matchesByDay = cached
            await wireLive()
            return
        }

        isLoading = true
        defer { isLoading = false }

        let days = weekDays
        let from = Self.iso(days.first ?? weekStart)
        let to = Self.iso(days.last ?? weekStart)
        var result: [Date: [Match]] = [:]

        if let summary = try? await api.getSchedule(from: from, to: to, team: teamFilter) {
            for match in summary.matches {
                result[calendar.startOfDay(for: match.date), default: []].append(match)
            }
            // The compound response also carries everything else the schedule needs.
            if !summary.teams.isEmpty { teams = summary.teams }
            if !summary.gameDays.isEmpty { gameDayKeys = Set(summary.gameDays) }
            if let next = summary.nextScheduled { serverNextScheduled = calendar.startOfDay(for: next.date) }
            for live in summary.live {
                if live.gameState == .played || live.gameState == .cancelled {
                    liveMatches.removeValue(forKey: live.externalId)
                } else {
                    liveMatches[live.externalId] = live
                }
            }
        } else {
            // v1 fallback — fetch each day in parallel (loads only the visible week).
            let team = teamFilter
            let api = self.api
            let cal = self.calendar
            let dayStrings = days.map { (cal.startOfDay(for: $0), Self.iso($0)) }
            let fetched: [(Date, [Match])] = await withTaskGroup(of: (Date, [Match]).self) { group in
                for (day, str) in dayStrings {
                    group.addTask {
                        let resp = try? await api.searchMatches(date: str, team: team, page: 1, limit: 50)
                        return (day, resp?.data ?? [])
                    }
                }
                var acc: [(Date, [Match])] = []
                for await pair in group { acc.append(pair) }
                return acc
            }
            for (day, matches) in fetched { result[day] = matches }
        }

        matchesByDay = result
        weekCache[key] = result
        await wireLive()
    }

    func stop() {
        cancellable?.cancel()
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Live wiring (today's games, when in view)

    private func wireLive() async {
        await refreshLive()
        subscribeLive()
        startPolling()
    }

    private func refreshLive() async {
        for match in todayVisibleGames {
            guard let live = try? await api.getLiveMatch(id: match.externalUUID) else { continue }
            if live.gameState == .played || live.gameState == .cancelled {
                liveMatches.removeValue(forKey: live.externalId)
            } else {
                liveMatches[live.externalId] = live
            }
        }
    }

    private func subscribeLive() {
        cancellable?.cancel()
        let ids = todayVisibleGames.map { $0.externalUUID }
        guard !ids.isEmpty else { return }

        cancellable = liveListener.subscribe(ids) { [weak self] gameUuid in
            guard let self else { return nil }
            guard let match = self.todayVisibleGames.first(where: { $0.externalUUID == gameUuid }) else { return nil }
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
        guard !todayVisibleGames.isEmpty else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refreshLive() }
        }
    }

    private func fetchTeamData(for match: Match) async -> (match: Match, homeTeam: Team, awayTeam: Team)? {
        guard let homeId = match.homeTeam.id, let awayId = match.awayTeam.id else { return nil }
        async let home = try? await api.getTeamDetail(id: homeId)
        async let away = try? await api.getTeamDetail(id: awayId)
        guard let h = await home, let a = await away else { return nil }
        return (match: match, homeTeam: h, awayTeam: a)
    }

    // MARK: - Date helpers

    static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    static func iso(_ date: Date) -> String { isoFormatter.string(from: date) }

    static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}

#if DEBUG
extension ScheduleViewModel {
    /// A view model preloaded with a week of mock games for previews (no network).
    static func preview() -> ScheduleViewModel {
        let vm = ScheduleViewModel()
        let cal = Calendar.current
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: vm.weekStart) ?? vm.weekStart }
        func mk(_ id: String, _ h: (String, String), _ a: (String, String),
                _ hs: Int, _ aws: Int, _ state: MatchState, _ date: Date, _ hour: Int) -> Match {
            let d = cal.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
            return Match(id: id, date: d, venue: "Arena",
                         homeTeam: TeamBasic(id: "t-\(h.0)", name: h.1, code: h.0),
                         awayTeam: TeamBasic(id: "t-\(a.0)", name: a.1, code: a.0),
                         homeScore: hs, awayScore: aws, state: state, overtime: false, shootout: false,
                         externalUUID: "x-\(id)")
        }
        let todayOffset = cal.dateComponents([.day], from: vm.weekStart, to: cal.startOfDay(for: Date())).day ?? 0
        let today = day(todayOffset)
        var byDay: [Date: [Match]] = [
            cal.startOfDay(for: today): [
                mk("t1", ("FHC", "Frölunda HC"), ("LHF", "Luleå HF"), 2, 1, .ongoing, today, 19),
                mk("t2", ("SAIK", "Skellefteå AIK"), ("RBK", "Rögle BK"), 0, 0, .ongoing, today, 19),
                mk("t3", ("FBK", "Färjestad BK"), ("VLH", "Växjö Lakers"), 0, 0, .scheduled, today, 19)
            ]
        ]
        if todayOffset + 2 <= 6 {
            byDay[cal.startOfDay(for: day(todayOffset + 2))] = [
                mk("f1", ("MODO", "MoDo Hockey"), ("FHC", "Frölunda HC"), 0, 0, .scheduled, day(todayOffset + 2), 15),
                mk("f2", ("LIF", "Leksands IF"), ("VLH", "Växjö Lakers"), 0, 0, .scheduled, day(todayOffset + 2), 18)
            ]
        }
        if todayOffset - 2 >= 0 {
            byDay[cal.startOfDay(for: day(todayOffset - 2))] = [
                mk("p1", ("FHC", "Frölunda HC"), ("MODO", "MoDo Hockey"), 4, 2, .played, day(todayOffset - 2), 19)
            ]
        }
        vm.matchesByDay = byDay
        vm.teams = [
            Team(id: "t-FHC", name: "Frölunda HC", code: "FHC", city: nil, founded: nil, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true),
            Team(id: "t-LHF", name: "Luleå HF", code: "LHF", city: nil, founded: nil, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true)
        ]
        return vm
    }
}
#endif
