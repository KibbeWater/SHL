//
//  PBPEventData.swift
//  SHL
//
//  Event-specific data structures for PBP events
//

import Foundation

// MARK: - Goal Event Data

/// Comprehensive goal event information
public struct GoalEventData: Codable, Equatable, Sendable {
    public let scorer: PlayerSummary
    public let assists: [PlayerSummary]?
    public let location: LocationData
    public let homeScore: Int
    public let awayScore: Int
    public let emptyNet: Bool
    public let penaltyShot: Bool
    public let gameWinningGoal: Bool?
    public let goalStatus: String? // "EQ", "PP1", "PP2", "SH"
    public let onIceScoring: [PlayerSummary]?
    public let onIceAgainst: [PlayerSummary]?

    public init(scorer: PlayerSummary, assists: [PlayerSummary]?, location: LocationData, homeScore: Int, awayScore: Int, emptyNet: Bool, penaltyShot: Bool, gameWinningGoal: Bool?, goalStatus: String?, onIceScoring: [PlayerSummary]?, onIceAgainst: [PlayerSummary]?) {
        self.scorer = scorer
        self.assists = assists
        self.location = location
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.emptyNet = emptyNet
        self.penaltyShot = penaltyShot
        self.gameWinningGoal = gameWinningGoal
        self.goalStatus = goalStatus
        self.onIceScoring = onIceScoring
        self.onIceAgainst = onIceAgainst
    }

    /// Returns the primary assist (first assist)
    public var primaryAssist: PlayerSummary? {
        assists?.first
    }

    /// Returns the secondary assist (second assist)
    public var secondaryAssist: PlayerSummary? {
        guard let assists = assists, assists.count > 1 else { return nil }
        return assists[1]
    }

    /// True if goal was scored at even strength
    public var isEvenStrength: Bool {
        goalStatus == "EQ"
    }

    /// True if goal was scored on power play
    public var isPowerPlay: Bool {
        goalStatus == "PP1" || goalStatus == "PP2"
    }

    /// True if goal was scored short-handed
    public var isShortHanded: Bool {
        goalStatus == "SH"
    }
}

// MARK: - Shot Event Data

/// Shot attempt information
public struct ShotEventData: Codable, Equatable, Sendable {
    public let shooter: PlayerSummary
    public let location: LocationData
    public let penaltyShot: Bool

    public init(shooter: PlayerSummary, location: LocationData, penaltyShot: Bool) {
        self.shooter = shooter
        self.location = location
        self.penaltyShot = penaltyShot
    }

    /// True if shot was on target (not blocked or missed)
    public var isOnTarget: Bool {
        location.isOnTarget
    }
}

// MARK: - Penalty Event Data

/// Penalty event details
public struct PenaltyEventData: Codable, Equatable, Sendable {
    public let player: PlayerSummary? // Null for bench penalties
    public let offence: String
    public let duration: Int? // Minutes
    public let penaltyType: String? // "minor", "major", "misconduct", etc.
    public let didRenderInPenaltyShot: Bool

    public init(player: PlayerSummary?, offence: String, duration: Int?, penaltyType: String?, didRenderInPenaltyShot: Bool) {
        self.player = player
        self.offence = offence
        self.duration = duration
        self.penaltyType = penaltyType
        self.didRenderInPenaltyShot = didRenderInPenaltyShot
    }

    /// True if this is a bench penalty
    public var isBenchPenalty: Bool {
        player == nil
    }

    /// True if this is a minor penalty (2 minutes)
    public var isMinor: Bool {
        duration == 2
    }

    /// True if this is a major penalty (5 minutes)
    public var isMajor: Bool {
        duration == 5
    }
}

// MARK: - Goalkeeper Event Data

/// Goalkeeper change information
public struct GoalkeeperEventData: Codable, Equatable, Sendable {
    public let goalie: PlayerSummary
    public let entering: Bool

    public init(goalie: PlayerSummary, entering: Bool) {
        self.goalie = goalie
        self.entering = entering
    }

    /// True if goalie is leaving the ice
    public var isLeaving: Bool {
        !entering
    }
}

// MARK: - Timeout Event Data

/// Team timeout information
public struct TimeoutEventData: Codable, Equatable, Sendable {
    public let team: TeamSummary

    public init(team: TeamSummary) {
        self.team = team
    }
}

// MARK: - Shootout Event Data

/// Shootout attempt details
public struct ShootoutEventData: Codable, Equatable, Sendable {
    public let shooter: PlayerSummary
    public let location: LocationData
    public let isGoal: Bool
    public let isGameWinner: Bool
    public let shootoutIndex: Int
    public let shootoutScore: ShootoutScore

    public init(shooter: PlayerSummary, location: LocationData, isGoal: Bool, isGameWinner: Bool, shootoutIndex: Int, shootoutScore: ShootoutScore) {
        self.shooter = shooter
        self.location = location
        self.isGoal = isGoal
        self.isGameWinner = isGameWinner
        self.shootoutIndex = shootoutIndex
        self.shootoutScore = shootoutScore
    }

    /// The round number (1, 2, 3, etc.)
    public var round: Int {
        (shootoutIndex + 1) / 2 + ((shootoutIndex + 1) % 2)
    }
}

// MARK: - Period Event Data

/// Period timing information
public struct PeriodEventData: Codable, Equatable, Sendable {
    public let started: Bool
    public let finished: Bool
    public let startedAt: String?
    public let finishedAt: String?

    public init(started: Bool, finished: Bool, startedAt: String?, finishedAt: String?) {
        self.started = started
        self.finished = finished
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }

    /// True if period is currently in progress
    public var isInProgress: Bool {
        started && !finished
    }
}

// MARK: - Period Change Data

/// Period transition marker (synthetic event created by controller)
public struct PeriodChangeData: Codable, Equatable, Sendable {
    public let fromPeriod: Int
    public let toPeriod: Int

    public init(fromPeriod: Int, toPeriod: Int) {
        self.fromPeriod = fromPeriod
        self.toPeriod = toPeriod
    }

    /// True if transitioning to overtime (period 4)
    public var isToOvertime: Bool {
        toPeriod == 4
    }

    /// True if transitioning to shootout (period 5)
    public var isToShootout: Bool {
        toPeriod == 5
    }

    /// Human-readable from label
    public var fromLabel: String {
        periodLabel(fromPeriod)
    }

    /// Human-readable to label
    public var toLabel: String {
        periodLabel(toPeriod)
    }

    /// Human-readable transition label
    public var transitionLabel: String {
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
