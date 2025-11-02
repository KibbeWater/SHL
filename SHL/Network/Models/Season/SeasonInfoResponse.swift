//
//  SeasonInfoResponse.swift
//  SHL
//

public struct SeasonInfoResponse: Codable {
    let season: Season
    let teams: [Team]
    let standings: [Standings]
}
