//
//  Series.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct Series: Codable, Identifiable {
    public let id: String
    public let name: String
    public let type: String // "regular", "playoffs", etc.
    public let seasonId: String
    public let isCurrent: Bool

    public init(id: String, name: String, type: String, seasonId: String, isCurrent: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.seasonId = seasonId
        self.isCurrent = isCurrent
    }
}
