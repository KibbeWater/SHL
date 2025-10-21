//
//  Team.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Team: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let code: String
    let city: String?
    let founded: Int?
    let venue: String?
    let golds: Int?
    let goldYears: [Int]?
    let finals: Int?
    let finalYears: [Int]?
    // let retiredNumbers: [String]?
    let isActive: Bool
}

extension Team {
    static func fromDetail(_ team: TeamDetail) -> Team {
        Team(id: team.id, name: team.name, code: team.code, city: team.city, founded: team.founded, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, isActive: team.isActive)
    }
}
