//
//  LiveMatch.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 25/10/25.
//
import Foundation

public struct LiveMatch: Codable, Equatable {
    // Basic game information
    public let id: String // Internal database UUID
    public let externalId: String // External match UUID
    public let homeTeam: Team
    public let awayTeam: Team

    // Live game overview
    public let homeScore: Int
    public let awayScore: Int
    public let period: Int
    public let periodTime: String
    public let periodEnd: Date // Timestamp when current period ends
    public let gameState: MatchState

    public init(id: String, externalId: String, homeTeam: Team, awayTeam: Team, homeScore: Int, awayScore: Int, period: Int, periodTime: String, periodEnd: Date, gameState: MatchState) {
        self.id = id
        self.externalId = externalId
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.period = period
        self.periodTime = periodTime
        self.periodEnd = periodEnd
        self.gameState = gameState
    }
}

public struct MatchTime: Codable {
    public let period: Int
    public let timeRemaining: Date

    public init(period: Int, timeRemaining: Date) {
        self.period = period
        self.timeRemaining = timeRemaining
    }
}

extension LiveMatch {
    /// Create LiveMatch from native LiveGameUpdate
    public static func fromLiveGameUpdate(_ update: LiveGameUpdate, match: Match, homeTeam: Team, awayTeam: Team) -> LiveMatch {
        // Convert seconds to MM:SS format
        let minutes = update.periodTime / 60
        let seconds = update.periodTime % 60
        let periodTimeString = String(format: "%02d:%02d", minutes, seconds)

        // Calculate period end time
        let remainingSeconds = update.periodEnd - update.periodTime
        let periodEnd = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        // Map game state to match state
        let gameState: MatchState
        switch update.state {
        case .notStarted:
            gameState = .scheduled
        case .ongoing, .overtime:
            gameState = .ongoing
        case .periodBreak:
            gameState = .paused
        case .gameEnded:
            gameState = .played
        }

        return LiveMatch(
            id: match.id,
            externalId: update.gameUuid,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: update.homeTeam.score,
            awayScore: update.awayTeam.score,
            period: update.period,
            periodTime: periodTimeString,
            periodEnd: periodEnd,
            gameState: gameState
        )
    }
}
