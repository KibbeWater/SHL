//
//  Match.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Match: Codable, Identifiable {
    let id: String
    let date: Date
    let venue: String?
    let homeTeam: TeamBasic
    let awayTeam: TeamBasic
    let homeScore: Int
    let awayScore: Int
    let gameState: MatchState
    let overtime: Bool?
    let shootout: Bool?

    var played: Bool {
        gameState == .played
    }

    func isLive() -> Bool {
        gameState == .ongoing
    }
}

struct TeamBasic: Codable {
    let id: String?
    let name: String
    let code: String
}

enum MatchState: String, Codable {
    case scheduled = "scheduled"
    case ongoing = "ongoing"
    case paused = "paused"
    case played = "played"
}
