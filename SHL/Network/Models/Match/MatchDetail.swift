//
//  MatchDetail.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct MatchDetail: Codable, Identifiable {
    let id: String
    let date: Date
    let venue: String?
    let homeTeam: TeamInMatch
    let awayTeam: TeamInMatch
    let homeScore: Int
    let awayScore: Int
    let gameState: MatchState
    let overtime: Bool?
    let shootout: Bool?
    let period: Int?
    let timeRemaining: Int? // seconds
    let attendance: Int?
    let officials: [Official]?
}

struct TeamInMatch: Codable {
    let id: String?
    let uuid: String
    let name: String
    let code: String
    let logoUrl: String?
}

struct Official: Codable {
    let name: String
    let role: String
}
