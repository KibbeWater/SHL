//
//  MatchStats.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct MatchStats: Codable {
    let id: String
    let matchID: String
    let teamID: String

    // Core statistics
    let goals: Int
    let shotsOnGoal: Int
    let saves: Int
    let faceoffsWon: Int

    // Extended statistics
    let faceoffsLost: Int?
    let penaltyMinutes: Int?
    let powerplayGoals: Int?
    let powerplayOpportunities: Int?
    let hits: Int?
    let blockedShots: Int?

    // Flexible storage for all raw statistics
    let extraStats: [String: Int]?
}

struct TeamStats: Codable {
    let teamId: String
    let teamCode: String
    let shots: Int
    let saves: Int
    let faceoffs: Int
    let faceoffsWon: Int
    let penalties: Int
    let penaltyMinutes: Int
    let powerPlayGoals: Int
    let powerPlayOpportunities: Int
    let shortHandedGoals: Int
    let hits: Int?
    let blocked: Int?
    let giveaways: Int?
    let takeaways: Int?
}

struct PlayerMatchStats: Codable {
    let playerId: String
    let playerName: String
    let jerseyNumber: Int
    let position: String
    let goals: Int
    let assists: Int
    let points: Int
    let plusMinus: Int
    let pim: Int
    let shots: Int
    let toi: String? // Time on ice
    let fow: Int? // Faceoffs won
    let fol: Int? // Faceoffs lost
}
