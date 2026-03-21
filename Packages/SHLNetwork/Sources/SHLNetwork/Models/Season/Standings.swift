//
//  Standings.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct Standings: Codable {
    public let id: String
    public let seasonID: String
    public let team: Team
    public let rank: Int
    public let gamesPlayed: Int
    public let points: Int
    public let goalDifference: Int
    public let wins: Int?
    public let overtimeWins: Int?
    public let losses: Int?
    public let overtimeLosses: Int?
    public let goalsFor: Int?
    public let goalsAgainst: Int?

    public init(id: String, seasonID: String, team: Team, rank: Int, gamesPlayed: Int, points: Int, goalDifference: Int, wins: Int?, overtimeWins: Int?, losses: Int?, overtimeLosses: Int?, goalsFor: Int?, goalsAgainst: Int?) {
        self.id = id
        self.seasonID = seasonID
        self.team = team
        self.rank = rank
        self.gamesPlayed = gamesPlayed
        self.points = points
        self.goalDifference = goalDifference
        self.wins = wins
        self.overtimeWins = overtimeWins
        self.losses = losses
        self.overtimeLosses = overtimeLosses
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
    }
}
