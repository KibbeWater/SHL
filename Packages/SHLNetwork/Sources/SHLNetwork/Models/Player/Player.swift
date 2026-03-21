//
//  Player.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct Player: Codable, Identifiable, Equatable {
    public let id: String
    public let externalUUID: String
    public let firstName: String
    public let lastName: String
    public let fullName: String
    public let birthDate: Date?
    public let nationality: Nationality?
    public let position: PositionCode?
    public let jerseyNumber: Int?
    public let height: Float?
    public let weight: Float?
    public let teamID: String
    public let team: Team?
    public let portraitURL: String?

    public init(id: String, externalUUID: String, firstName: String, lastName: String, fullName: String, birthDate: Date?, nationality: Nationality?, position: PositionCode?, jerseyNumber: Int?, height: Float?, weight: Float?, teamID: String, team: Team?, portraitURL: String?) {
        self.id = id
        self.externalUUID = externalUUID
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.birthDate = birthDate
        self.nationality = nationality
        self.position = position
        self.jerseyNumber = jerseyNumber
        self.height = height
        self.weight = weight
        self.teamID = teamID
        self.team = team
        self.portraitURL = portraitURL
    }
}

public enum Nationality: Codable, Sendable, Hashable, Equatable {
    case sweden
    case norway
    case finland
    case usa
    case canada
    case unknown(String)

    // Custom keys for encoding and decoding
    private enum CodingKeys: String, CodingKey {
        case sweden = "SE"
        case norway = "NO"
        case finland = "FI"
        case usa = "US"
        case canada = "CA"
        case unknown
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        switch value {
        case "SE":
            self = .sweden
        case "NO":
            self = .norway
        case "FI":
            self = .finland
        case "US":
            self = .usa
        case "CA":
            self = .canada
        default:
            self = .unknown(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .sweden:
            try container.encode("SE")
        case .norway:
            try container.encode("NO")
        case .finland:
            try container.encode("FI")
        case .usa:
            try container.encode("US")
        case .canada:
            try container.encode("CA")
        case .unknown(let value):
            try container.encode(value)
        }
    }
}

public enum PositionCode: String, Codable, Sendable {
    case goalkeeper = "GK"
    case defense = "D"
    case forward = "F"
}
