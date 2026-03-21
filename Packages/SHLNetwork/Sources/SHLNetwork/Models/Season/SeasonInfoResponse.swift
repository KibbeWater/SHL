//
//  SeasonInfoResponse.swift
//  SHL
//

import Foundation

public struct SeasonInfoResponse: Codable {
    public let season: Season
    public let teams: [Team]
    public let standings: [Standings]

    public init(season: Season, teams: [Team], standings: [Standings]) {
        self.season = season
        self.teams = teams
        self.standings = standings
    }
}
