//
//  LiveMatch.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 25/10/25.
//
import Foundation

public struct LiveMatch: Codable {
    // Basic game information
    public let id: String // Internal database UUID
    public let externalId: String // External match UUID
    let homeTeam: Team
    let awayTeam: Team

    // Live game overview
    let homeScore: Int
    let awayScore: Int
    let period: Int
    let periodTime: String
    let periodEnd: Date // Timestamp when current period ends
    public let gameState: MatchState
}

struct MatchTime: Codable {
    let period: Int
    let timeRemaining: Date
}

extension LiveMatch {
    /// Create LiveMatch from native LiveGameUpdate
    static func fromLiveGameUpdate(_ update: LiveGameUpdate, match: Match, homeTeam: Team, awayTeam: Team) -> LiveMatch {
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
