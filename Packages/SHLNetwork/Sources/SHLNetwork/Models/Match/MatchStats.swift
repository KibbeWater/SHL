//
//  MatchStats.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct MatchStats: Codable, Equatable {
    public let id: String
    public let matchID: String
    public let teamID: String

    // Core statistics
    public let goals: Int
    public let shotsOnGoal: Int
    public let saves: Int
    public let faceoffsWon: Int

    // Extended statistics
    public let faceoffsLost: Int?
    public let penaltyMinutes: Int?
    public let powerplayGoals: Int?
    public let powerplayOpportunities: Int?
    public let hits: Int?
    public let blockedShots: Int?

    // Flexible storage for all raw statistics
    public let extraStats: [String: Int]?

    public init(id: String, matchID: String, teamID: String, goals: Int, shotsOnGoal: Int, saves: Int, faceoffsWon: Int, faceoffsLost: Int?, penaltyMinutes: Int?, powerplayGoals: Int?, powerplayOpportunities: Int?, hits: Int?, blockedShots: Int?, extraStats: [String: Int]?) {
        self.id = id
        self.matchID = matchID
        self.teamID = teamID
        self.goals = goals
        self.shotsOnGoal = shotsOnGoal
        self.saves = saves
        self.faceoffsWon = faceoffsWon
        self.faceoffsLost = faceoffsLost
        self.penaltyMinutes = penaltyMinutes
        self.powerplayGoals = powerplayGoals
        self.powerplayOpportunities = powerplayOpportunities
        self.hits = hits
        self.blockedShots = blockedShots
        self.extraStats = extraStats
    }
}

public struct TeamStats: Codable {
    public let teamId: String
    public let teamCode: String
    public let shots: Int
    public let saves: Int
    public let faceoffs: Int
    public let faceoffsWon: Int
    public let penalties: Int
    public let penaltyMinutes: Int
    public let powerPlayGoals: Int
    public let powerPlayOpportunities: Int
    public let shortHandedGoals: Int
    public let hits: Int?
    public let blocked: Int?
    public let giveaways: Int?
    public let takeaways: Int?

    public init(teamId: String, teamCode: String, shots: Int, saves: Int, faceoffs: Int, faceoffsWon: Int, penalties: Int, penaltyMinutes: Int, powerPlayGoals: Int, powerPlayOpportunities: Int, shortHandedGoals: Int, hits: Int?, blocked: Int?, giveaways: Int?, takeaways: Int?) {
        self.teamId = teamId
        self.teamCode = teamCode
        self.shots = shots
        self.saves = saves
        self.faceoffs = faceoffs
        self.faceoffsWon = faceoffsWon
        self.penalties = penalties
        self.penaltyMinutes = penaltyMinutes
        self.powerPlayGoals = powerPlayGoals
        self.powerPlayOpportunities = powerPlayOpportunities
        self.shortHandedGoals = shortHandedGoals
        self.hits = hits
        self.blocked = blocked
        self.giveaways = giveaways
        self.takeaways = takeaways
    }
}

public struct PlayerMatchStats: Codable {
    public let playerId: String
    public let playerName: String
    public let jerseyNumber: Int
    public let position: String
    public let goals: Int
    public let assists: Int
    public let points: Int
    public let plusMinus: Int
    public let pim: Int
    public let shots: Int
    public let toi: String? // Time on ice
    public let fow: Int? // Faceoffs won
    public let fol: Int? // Faceoffs lost

    public init(playerId: String, playerName: String, jerseyNumber: Int, position: String, goals: Int, assists: Int, points: Int, plusMinus: Int, pim: Int, shots: Int, toi: String?, fow: Int?, fol: Int?) {
        self.playerId = playerId
        self.playerName = playerName
        self.jerseyNumber = jerseyNumber
        self.position = position
        self.goals = goals
        self.assists = assists
        self.points = points
        self.plusMinus = plusMinus
        self.pim = pim
        self.shots = shots
        self.toi = toi
        self.fow = fow
        self.fol = fol
    }
}
