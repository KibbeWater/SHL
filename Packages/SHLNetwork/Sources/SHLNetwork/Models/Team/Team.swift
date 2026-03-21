//
//  Team.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct Team: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let code: String
    public let city: String?
    public let founded: Int?
    public let venue: String?
    public let golds: Int?
    public let goldYears: [Int]?
    public let finals: Int?
    public let finalYears: [Int]?
    // let retiredNumbers: [String]?
    public let iconURL: String?
    public let isActive: Bool

    public init(id: String, name: String, code: String, city: String?, founded: Int?, venue: String?, golds: Int?, goldYears: [Int]?, finals: Int?, finalYears: [Int]?, iconURL: String?, isActive: Bool) {
        self.id = id
        self.name = name
        self.code = code
        self.city = city
        self.founded = founded
        self.venue = venue
        self.golds = golds
        self.goldYears = goldYears
        self.finals = finals
        self.finalYears = finalYears
        self.iconURL = iconURL
        self.isActive = isActive
    }
}

extension Team {
    public static func fromDetail(_ team: TeamDetail) -> Team {
        Team(id: team.id, name: team.name, code: team.code, city: team.city, founded: team.founded, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: team.logoUrl, isActive: team.isActive)
    }
}
