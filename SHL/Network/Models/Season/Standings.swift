//
//  Standings.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Standings: Codable {
    let id: String
    let seasonID: String
    let team: Team
    let rank: Int
    let gamesPlayed: Int
    let points: Int
    let goalDifference: Int
    let wins: Int?
    let losses: Int?
    let overtimeLosses: Int?
}
