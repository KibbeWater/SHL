//
//  TeamLineup.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct TeamLineup: Codable, Hashable {
    public let teamId: String
    public let teamName: String
    public let teamCode: String
    public let season: String?
    public let players: [LineupPlayer]

    public init(teamId: String, teamName: String, teamCode: String, season: String?, players: [LineupPlayer]) {
        self.teamId = teamId
        self.teamName = teamName
        self.teamCode = teamCode
        self.season = season
        self.players = players
    }
}

public struct LineupPlayer: Codable, Identifiable, Hashable {
    public let id: String
    public let uuid: String
    public let firstName: String
    public let lastName: String
    public let jerseyNumber: Int
    public let position: PositionCode?
    public let height: Int? // cm
    public let weight: Int? // kg
    public let birthDate: Date?
    public let nationality: Nationality?
    public let shoots: String? // "L" or "R"

    public var fullName: String {
        "\(firstName) \(lastName)"
    }

    public init(id: String, uuid: String, firstName: String, lastName: String, jerseyNumber: Int, position: PositionCode?, height: Int?, weight: Int?, birthDate: Date?, nationality: Nationality?, shoots: String?) {
        self.id = id
        self.uuid = uuid
        self.firstName = firstName
        self.lastName = lastName
        self.jerseyNumber = jerseyNumber
        self.position = position
        self.height = height
        self.weight = weight
        self.birthDate = birthDate
        self.nationality = nationality
        self.shoots = shoots
    }

    public static func fakeData() -> LineupPlayer {
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
