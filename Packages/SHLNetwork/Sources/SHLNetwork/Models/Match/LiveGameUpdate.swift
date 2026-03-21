//
//  LiveGameUpdate.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation

/// Clean, stable model for live game updates from SSE stream
/// This model abstracts away the unstable external API structure
public struct LiveGameUpdate: Codable, Sendable, Equatable {
    /// External game UUID (used for matching with Match.externalUUID)
    public let gameUuid: String

    /// SHL API game ID (optional, may not be available immediately)
    public let gameId: Int?

    /// Home team information
    public let homeTeam: TeamInfo

    /// Away team information
    public let awayTeam: TeamInfo

    /// Current period (1-3 for regulation, 4+ for overtime)
    public let period: Int

    /// Time elapsed in current period (in seconds)
    public let periodTime: Int

    /// Time when period ends (in seconds)
    public let periodEnd: Int

    /// Current game state
    public let state: GameState

    /// Timestamp when this update was received
    public let receivedAt: Date

    public struct TeamInfo: Codable, Sendable, Equatable {
        public let code: String
        public let score: Int

        public init(code: String, score: Int) {
            self.code = code
            self.score = score
        }
    }

    public enum GameState: String, Codable, Sendable {
        case notStarted = "NotStarted"
        case ongoing = "Ongoing"
        case periodBreak = "PeriodBreak"
        case overtime = "Overtime"
        case gameEnded = "GameEnded"

        /// Maps to Match.State for consistency
        public var matchState: String {
            switch self {
            case .notStarted:
                return "scheduled"
            case .ongoing, .overtime:
                return "ongoing"
            case .periodBreak:
                return "paused"
            case .gameEnded:
                return "played"
            }
        }
    }

    public init(
        gameUuid: String,
        gameId: Int?,
        homeTeam: TeamInfo,
        awayTeam: TeamInfo,
        period: Int,
        periodTime: Int,
        periodEnd: Int,
        state: GameState,
        receivedAt: Date = Date()
    ) {
        self.gameUuid = gameUuid
        self.gameId = gameId
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.period = period
        self.periodTime = periodTime
        self.periodEnd = periodEnd
        self.state = state
        self.receivedAt = receivedAt
    }
}
