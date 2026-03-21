//
//  Match.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct Match: Codable, Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let venue: String?
    public let homeTeam: TeamBasic
    public let awayTeam: TeamBasic
    public let homeScore: Int
    public let awayScore: Int
    public let state: MatchState
    public let overtime: Bool?
    public let shootout: Bool?
    public let externalUUID: String

    public var played: Bool {
        state == .played
    }

    public func isLive() -> Bool {
        state == .ongoing
    }

    public init(id: String, date: Date, venue: String?, homeTeam: TeamBasic, awayTeam: TeamBasic, homeScore: Int, awayScore: Int, state: MatchState, overtime: Bool?, shootout: Bool?, externalUUID: String) {
        self.id = id
        self.date = date
        self.venue = venue
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.state = state
        self.overtime = overtime
        self.shootout = shootout
        self.externalUUID = externalUUID
    }
}

public struct TeamBasic: Codable, Equatable {
    public let id: String?
    public let name: String
    public let code: String

    public init(id: String?, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
}

public enum MatchState: String, Codable {
    case scheduled
    case ongoing
    case paused
    case played
    case cancelled
}

public struct RecentMatchesResponse: Codable {
    public let upcoming: [Match]
    public let recent: [Match]

    public init(upcoming: [Match], recent: [Match]) {
        self.upcoming = upcoming
        self.recent = recent
    }
}
