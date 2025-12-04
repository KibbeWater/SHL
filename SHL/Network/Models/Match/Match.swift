//
//  Match.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Match: Codable, Identifiable, Equatable {
    let id: String
    let date: Date
    let venue: String?
    let homeTeam: TeamBasic
    let awayTeam: TeamBasic
    let homeScore: Int
    let awayScore: Int
    let state: MatchState
    let overtime: Bool?
    let shootout: Bool?
    let externalUUID: String

    var played: Bool {
        state == .played
    }

    func isLive() -> Bool {
        state == .ongoing
    }
}

public struct TeamBasic: Codable, Equatable {
    let id: String?
    let name: String
    let code: String
}

public enum MatchState: String, Codable {
    case scheduled
    case ongoing
    case paused
    case played
}

struct RecentMatchesResponse: Codable {
    let upcoming: [Match]
    let recent: [Match]
}
