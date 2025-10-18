//
//  Standings.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Standings: Codable {
    let ssgtUuid: String
    let seasonName: String
    let standings: [Standing]
}

struct Standing: Codable, Identifiable {
    let id: String
    let rank: Int
    let teamId: String
    let teamName: String
    let teamCode: String
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let overtimeLosses: Int
    let points: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifferential: Int

    var logoUrl: String? {
        // Can be computed based on team code or provided by API
        return nil
    }
}
