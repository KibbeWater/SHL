//
//  TeamLineup.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct TeamLineup: Codable {
    let teamId: String
    let teamName: String
    let teamCode: String
    let season: String?
    let players: [LineupPlayer]
}

struct LineupPlayer: Codable, Identifiable {
    let id: String
    let uuid: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int
    let position: String
    let height: Int? // cm
    let weight: Int? // kg
    let birthDate: Date?
    let nationality: String?
    let shoots: String? // "L" or "R"

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
