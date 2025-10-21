//
//  PlayerGameLog.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct PlayerGameLog: Codable, Identifiable, Hashable {
    let id: String
    let playerID: String
    let seasonID: String
    let gamesPlayed: Int
    let goals: Int
    let assists: Int
    let points: Int
    let penaltyMinutes: Int
    let plusMinus: Int?
}
