//
//  Player.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Player: Codable, Identifiable {
    let id: String
    let externalUUID: String
    let firstName: String
    let lastName: String
    let fullName: String
    let birthDate: Date?
    let nationality: Nationality?
    let position: PositionCode?
    let jerseyNumber: Int?
    let height: Float?
    let weight: Float?
    let teamID: String
    let team: Team?
    let portraitURL: String?
}

enum Nationality: Codable, Sendable, Hashable, Equatable {
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

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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

enum PositionCode: String, Codable, Sendable {
    case goalkeeper = "GK"
    case defense = "D"
    case forward = "F"
}
