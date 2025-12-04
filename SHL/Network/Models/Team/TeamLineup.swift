//
//  TeamLineup.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct TeamLineup: Codable, Hashable {
    let teamId: String
    let teamName: String
    let teamCode: String
    let season: String?
    let players: [LineupPlayer]
}

struct LineupPlayer: Codable, Identifiable, Hashable {
    let id: String
    let uuid: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int
    let position: PositionCode?
    let height: Int? // cm
    let weight: Int? // kg
    let birthDate: Date?
    let nationality: Nationality?
    let shoots: String? // "L" or "R"

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    static func fakeData() -> LineupPlayer {
        LineupPlayer(
            id: "fake-player-1",
            uuid: "fake-uuid-1",
            firstName: "John",
            lastName: "Doe",
            jerseyNumber: 99,
            position: PositionCode.defense,
            height: 185,
            weight: 90,
            birthDate: Date(),
            nationality: .sweden,
            shoots: "L"
        )
    }
}
