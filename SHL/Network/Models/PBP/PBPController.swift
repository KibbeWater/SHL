//
//  PBPController.swift
//  SHL
//
//  Controller for managing and manipulating PBP events
//

import Foundation

/// Controller class for managing Play-by-Play events with sorting, filtering, and utilities
@MainActor
class PBPController: ObservableObject {
    @Published private(set) var events: [PBPEventDTO]

    // MARK: - Initialization

    init(events: [PBPEventDTO] = []) {
        self.events = events
    }

    /// Load events from array
    func load(events: [PBPEventDTO]) {
        self.events = events
    }

    // MARK: - Sorting

    /// Sort events chronologically (oldest first)
    func sortChronological() -> [PBPEventDTO] {
        events.sorted { $0.realWorldTime < $1.realWorldTime }
    }

    /// Sort events reverse chronologically (newest first)
    func sortReverseChronological() -> [PBPEventDTO] {
        events.sorted { $0.realWorldTime > $1.realWorldTime }
    }

    /// Sort events by period and game time
    func sortByPeriodAndTime(ascending: Bool = true) -> [PBPEventDTO] {
        events.sorted { event1, event2 in
            if event1.period != event2.period {
                return ascending ? event1.period < event2.period : event1.period > event2.period
            }

            // Convert MM:SS to comparable format
            let time1Components = event1.gameTime.split(separator: ":").compactMap { Int($0) }
            let time2Components = event2.gameTime.split(separator: ":").compactMap { Int($0) }

            guard time1Components.count == 2, time2Components.count == 2 else {
                return ascending
            }

            let seconds1 = time1Components[0] * 60 + time1Components[1]
            let seconds2 = time2Components[0] * 60 + time2Components[1]

            return ascending ? seconds1 < seconds2 : seconds1 > seconds2
        }
    }

    /// Sort events with period change markers inserted between periods
    ///
    /// - Parameter reverse: Sort direction
    ///   - `false` (default): Chronological order (oldest first, Period 1 → Period 2 → Period 3)
    ///   - `true`: Reverse chronological order (newest first, Period 3 → Period 2 → Period 1)
    /// - Returns: Array of events with synthetic period change markers inserted between periods
    func sortedWithPeriodMarkers(reverse: Bool = false) -> [PBPEventDTO] {
        // Filter out any existing period change markers first to avoid duplicates
        let eventsWithoutMarkers = events.filter { $0.typedEventType != .periodChange }
        let sorted = reverse
            ? eventsWithoutMarkers.sorted { $0.realWorldTime > $1.realWorldTime }
            : eventsWithoutMarkers.sorted { $0.realWorldTime < $1.realWorldTime }
        guard !sorted.isEmpty else { return [] }

        var result: [PBPEventDTO] = []
        var previousPeriod: Int?

        for event in sorted {
            // Check if period changed
            if let prev = previousPeriod, prev != event.period {
                // Create synthetic period change event
                let periodChangeData = PeriodChangeData(fromPeriod: prev, toPeriod: event.period)
                let markerEvent = PBPEventDTO(
                    id: "period-change-\(prev)-\(event.period)",
                    matchID: event.matchID,
                    eventType: "period-change",
                    period: event.period,
                    gameTime: "00:00",
                    realWorldTime: event.realWorldTime,
                    teamID: nil,
                    playerID: nil,
                    description: periodChangeData.transitionLabel,
                    data: .periodChange(periodChangeData)
                )
                result.append(markerEvent)
            }

            result.append(event)
            previousPeriod = event.period
        }

        return result
    }

    // MARK: - Filtering

    /// Filter events by type
    func filter(by eventType: PBPEventTypeEnum) -> [PBPEventDTO] {
        events.filter { $0.typedEventType == eventType }
    }

    /// Filter events by multiple types
    func filter(byTypes eventTypes: [PBPEventTypeEnum]) -> [PBPEventDTO] {
        events.filter { eventTypes.contains($0.typedEventType) }
    }

    /// Filter events by period
    func filter(byPeriod period: Int) -> [PBPEventDTO] {
        events.filter { $0.period == period }
    }

    /// Filter events by team ID
    func filter(byTeamID teamID: String) -> [PBPEventDTO] {
        events.filter { $0.teamID == teamID }
    }

    // MARK: - Specific Event Type Accessors

    /// Get all goal events
    var goals: [PBPEventDTO] {
        filter(by: .goal)
    }

    /// Get all shot events (excluding goals)
    var shots: [PBPEventDTO] {
        filter(by: .shot)
    }

    /// Get all penalty events
    var penalties: [PBPEventDTO] {
        filter(by: .penalty)
    }

    /// Get all goalkeeper change events
    var goalkeeperChanges: [PBPEventDTO] {
        filter(by: .goalkeeper)
    }

    /// Get all timeout events
    var timeouts: [PBPEventDTO] {
        filter(by: .timeout)
    }

    /// Get all shootout events
    var shootouts: [PBPEventDTO] {
        filter(by: .shootout)
    }

    /// Get all period events
    var periodEvents: [PBPEventDTO] {
        filter(by: .period)
    }

    // MARK: - Timeline & Play-by-Play View

    /// Get events in chronological order for a timeline view
    var timeline: [PBPEventDTO] {
        sortChronological()
    }

    /// Get events in reverse chronological order (most recent first)
    var reverseTimeline: [PBPEventDTO] {
        sortReverseChronological()
    }

    /// Get events grouped by period
    func groupedByPeriod() -> [Int: [PBPEventDTO]] {
        Dictionary(grouping: events) { $0.period }
    }

    // MARK: - Statistics

    /// Total number of events
    var totalEvents: Int {
        events.count
    }

    /// Get goal count for a specific team
    func goalCount(forTeamID teamID: String) -> Int {
        goals.filter { $0.teamID == teamID }.count
    }

    /// Get penalty count for a specific team
    func penaltyCount(forTeamID teamID: String) -> Int {
        penalties.filter { $0.teamID == teamID }.count
    }

    /// Get shot count for a specific team (including goals)
    func shotCount(forTeamID teamID: String, includeGoals: Bool = true) -> Int {
        let shotEvents = shots.filter { $0.teamID == teamID }
        if includeGoals {
            return shotEvents.count + goalCount(forTeamID: teamID)
        }
        return shotEvents.count
    }

    // MARK: - Advanced Queries

    /// Get all scoring plays (goals) in chronological order
    var scoringPlays: [PBPEventDTO] {
        goals.sorted { $0.realWorldTime < $1.realWorldTime }
    }

    /// Get power play goals for a team
    func powerPlayGoals(forTeamID teamID: String) -> [PBPEventDTO] {
        goals.filter { event in
            guard event.teamID == teamID,
                  let goalData = event.data?.asGoal else {
                return false
            }
            return goalData.isPowerPlay
        }
    }

    /// Get short-handed goals for a team
    func shortHandedGoals(forTeamID teamID: String) -> [PBPEventDTO] {
        goals.filter { event in
            guard event.teamID == teamID,
                  let goalData = event.data?.asGoal else {
                return false
            }
            return goalData.isShortHanded
        }
    }

    /// Get empty net goals
    var emptyNetGoals: [PBPEventDTO] {
        goals.filter { event in
            event.data?.asGoal?.emptyNet == true
        }
    }

    /// Get game-winning goal
    var gameWinningGoal: PBPEventDTO? {
        goals.first { event in
            event.data?.asGoal?.gameWinningGoal == true
        }
    }

    // MARK: - Convenience Methods

    /// Check if there are any events
    var hasEvents: Bool {
        !events.isEmpty
    }

    /// Get the most recent event
    var mostRecentEvent: PBPEventDTO? {
        events.max(by: { $0.realWorldTime < $1.realWorldTime })
    }

    /// Get the first event
    var firstEvent: PBPEventDTO? {
        events.min(by: { $0.realWorldTime < $1.realWorldTime })
    }

    /// Clear all events
    func clear() {
        events = []
    }
}

// MARK: - Convenience Extensions

extension PBPController {
    /// Create a filtered copy of this controller
    func filtered(by eventType: PBPEventTypeEnum) -> PBPController {
        PBPController(events: filter(by: eventType))
    }

    /// Create a filtered copy for a specific period
    func filtered(byPeriod period: Int) -> PBPController {
        PBPController(events: filter(byPeriod: period))
    }

    /// Create a filtered copy for a specific team
    func filtered(byTeamID teamID: String) -> PBPController {
        PBPController(events: filter(byTeamID: teamID))
    }
}
