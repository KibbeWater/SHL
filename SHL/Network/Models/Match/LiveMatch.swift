//
//  LiveMatch.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 25/10/25.
//
import Foundation
import HockeyKit

public struct LiveMatch: Codable {
    // Basic game information
    public let id: String // Internal database UUID
    public let externalId: String // HockeyKit match UUID
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
    static func fromGameData(_ game: GameData, match: Match, homeTeam: Team, awayTeam: Team) -> LiveMatch {
        let gameOverview = game.gameOverview
        var gameState: MatchState = .ongoing

        switch gameOverview.state {
        case .starting:
            gameState = .scheduled
        case .ongoing:
            gameState = .ongoing
        case .onbreak:
            gameState = .paused
        case .overtime:
            gameState = .ongoing
        case .ended:
            gameState = .played
        }

        return LiveMatch(
            id: match.id,
            externalId: gameOverview.gameUuid,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: gameOverview.homeGoals,
            awayScore: gameOverview.awayGoals,
            period: gameOverview.time.period,
            periodTime: gameOverview.time.periodTime,
            periodEnd: gameOverview.time.periodEnd ?? Date.now,
            gameState: gameState
        )
    }
}

struct GameDataResponse: Codable {
    let data: GameData
}
