//
//  Player.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Player: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int
    let position: String
    let height: Int? // cm
    let weight: Int? // kg
    let birthDate: Date?
    let birthPlace: String?
    let nationality: String?
    let shoots: String? // "L" or "R"
    let currentTeam: PlayerTeam?
    let imageUrl: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct PlayerTeam: Codable {
    let id: String
    let name: String
    let code: String
}
