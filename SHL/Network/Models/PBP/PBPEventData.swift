//
//  PBPEventData.swift
//  SHL
//
//  Event-specific data structures for PBP events
//

import Foundation

// MARK: - Goal Event Data

/// Comprehensive goal event information
struct GoalEventData: Codable, Equatable, Sendable {
    let scorer: PlayerSummary
    let assists: [PlayerSummary]?
    let location: LocationData
    let homeScore: Int
    let awayScore: Int
    let emptyNet: Bool
    let penaltyShot: Bool
    let gameWinningGoal: Bool?
    let goalStatus: String? // "EQ", "PP1", "PP2", "SH"
    let onIceScoring: [PlayerSummary]?
    let onIceAgainst: [PlayerSummary]?

    /// Returns the primary assist (first assist)
    var primaryAssist: PlayerSummary? {
        assists?.first
    }

    /// Returns the secondary assist (second assist)
    var secondaryAssist: PlayerSummary? {
        guard let assists = assists, assists.count > 1 else { return nil }
        return assists[1]
    }

    /// True if goal was scored at even strength
    var isEvenStrength: Bool {
        goalStatus == "EQ"
    }

    /// True if goal was scored on power play
    var isPowerPlay: Bool {
        goalStatus == "PP1" || goalStatus == "PP2"
    }

    /// True if goal was scored short-handed
    var isShortHanded: Bool {
        goalStatus == "SH"
    }
}

// MARK: - Shot Event Data

/// Shot attempt information
struct ShotEventData: Codable, Equatable, Sendable {
    let shooter: PlayerSummary
    let location: LocationData
    let penaltyShot: Bool

    /// True if shot was on target (not blocked or missed)
    var isOnTarget: Bool {
        location.isOnTarget
    }
}

// MARK: - Penalty Event Data

/// Penalty event details
struct PenaltyEventData: Codable, Equatable, Sendable {
    let player: PlayerSummary? // Null for bench penalties
    let offence: String
    let duration: Int? // Minutes
    let penaltyType: String? // "minor", "major", "misconduct", etc.
    let didRenderInPenaltyShot: Bool

    /// True if this is a bench penalty
    var isBenchPenalty: Bool {
        player == nil
    }

    /// True if this is a minor penalty (2 minutes)
    var isMinor: Bool {
        duration == 2
    }

    /// True if this is a major penalty (5 minutes)
    var isMajor: Bool {
        duration == 5
    }
}

// MARK: - Goalkeeper Event Data

/// Goalkeeper change information
struct GoalkeeperEventData: Codable, Equatable, Sendable {
    let goalie: PlayerSummary
    let entering: Bool

    /// True if goalie is leaving the ice
    var isLeaving: Bool {
        !entering
    }
}

// MARK: - Timeout Event Data

/// Team timeout information
struct TimeoutEventData: Codable, Equatable, Sendable {
    let team: TeamSummary
}

// MARK: - Shootout Event Data

/// Shootout attempt details
struct ShootoutEventData: Codable, Equatable, Sendable {
    let shooter: PlayerSummary
    let location: LocationData
    let isGoal: Bool
    let isGameWinner: Bool
    let shootoutIndex: Int
    let shootoutScore: ShootoutScore

    /// The round number (1, 2, 3, etc.)
    var round: Int {
        (shootoutIndex + 1) / 2 + ((shootoutIndex + 1) % 2)
    }
}

// MARK: - Period Event Data

/// Period timing information
struct PeriodEventData: Codable, Equatable, Sendable {
    let started: Bool
    let finished: Bool
    let startedAt: String?
    let finishedAt: String?

    /// True if period is currently in progress
    var isInProgress: Bool {
        started && !finished
    }
}

// MARK: - Period Change Data

/// Period transition marker (synthetic event created by controller)
struct PeriodChangeData: Codable, Equatable, Sendable {
    let fromPeriod: Int
    let toPeriod: Int

    /// True if transitioning to overtime (period 4)
    var isToOvertime: Bool {
        toPeriod == 4
    }

    /// True if transitioning to shootout (period 5)
    var isToShootout: Bool {
        toPeriod == 5
    }
    
    /// Human-readable from label
    var fromLabel: String {
        periodLabel(fromPeriod)
    }
    
    /// Human-readable to label
    var toLabel: String {
        periodLabel(toPeriod)
    }

    /// Human-readable transition label
    var transitionLabel: String {
        let fromLabel = periodLabel(fromPeriod)
        let toLabel = periodLabel(toPeriod)
        return "\(fromLabel) → \(toLabel)"
    }

    /// Get display label for a period number
    private func periodLabel(_ period: Int) -> String {
        switch period {
        case 4:
            return "Overtime"
        case 5:
            return "Shootout"
        default:
            return "Period \(period)"
        }
    }
}
