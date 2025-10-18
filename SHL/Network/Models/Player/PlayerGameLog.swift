//
//  PlayerGameLog.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct PlayerGameLog: Codable, Identifiable {
    let id: String
    let playerId: String
    let matchId: String
    let date: Date
    let opponent: String
    let opponentCode: String
    let homeAway: String // "home" or "away"
    let goals: Int
    let assists: Int
    let points: Int
    let plusMinus: Int
    let pim: Int // Penalty minutes
    let shots: Int
    let toi: String? // Time on ice
    let gameWinningGoal: Bool?
    let powerPlayGoals: Int?
    let powerPlayAssists: Int?
    let shortHandedGoals: Int?
    let shortHandedAssists: Int?
}
