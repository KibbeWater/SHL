//
//  LiveMatch.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 25/10/25.
//
import Foundation
import HockeyKit

struct LiveMatch: Codable {
    // Basic game information
    let id: String              // Internal database UUID
    let externalId: String      // HockeyKit match UUID
    let homeTeam: Team
    let awayTeam: Team

    // Live game overview
    let homeScore: Int
    let awayScore: Int
    let period: Int
    let timeRemaining: Date
    let gameState: MatchTime
}

struct MatchTime: Codable {
    let period: Int
    let timeRemaining: Date
}

struct GameDataResponse: Codable {
    let data: GameData
}
