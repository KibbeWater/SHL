//
//  PlayerGameLog.swift
//  SHL
//
//  Created by Migration Script
//  Updated to match backend PlayerStatDTO structure
//

import Foundation

// MARK: - Game Type Enum
public enum GameType: String, Codable {
    case regular
    case playoff
}

// MARK: - Series DTO
public struct SeriesDTO: Codable, Hashable {
    public let id: String
    public let code: String
    public let name: String
    public let externalUUID: String
    public let gender: String?
    public let country: String
    public let priority: Int
    public let isActive: Bool

    public init(id: String, code: String, name: String, externalUUID: String, gender: String?, country: String, priority: Int, isActive: Bool) {
        self.id = id
        self.code = code
        self.name = name
        self.externalUUID = externalUUID
        self.gender = gender
        self.country = country
        self.priority = priority
        self.isActive = isActive
    }
}

// MARK: - Season DTO
public struct SeasonDTO: Codable, Hashable {
    public let id: String
    public let series: SeriesDTO
    public let externalUUID: String
    public let code: String
    public let name: String
    public let startDate: Date?
    public let endDate: Date?
    public let isCurrent: Bool

    public init(id: String, series: SeriesDTO, externalUUID: String, code: String, name: String, startDate: Date?, endDate: Date?, isCurrent: Bool) {
        self.id = id
        self.series = series
        self.externalUUID = externalUUID
        self.code = code
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isCurrent = isCurrent
    }
}

// MARK: - Team DTO (for stats)
public struct StatTeamDTO: Codable, Hashable {
    public let id: String
    public let externalId: String?
    public let name: String
    public let code: String
    public let city: String?
    public let founded: Int?
    public let venue: String?
    public let golds: Int?
    public let goldYears: [Int]?
    public let finals: Int?
    public let finalYears: [Int]?
    public let retiredNumbers: [String]?
    public let isActive: Bool

    public init(id: String, externalId: String?, name: String, code: String, city: String?, founded: Int?, venue: String?, golds: Int?, goldYears: [Int]?, finals: Int?, finalYears: [Int]?, retiredNumbers: [String]?, isActive: Bool) {
        self.id = id
        self.externalId = externalId
        self.name = name
        self.code = code
        self.city = city
        self.founded = founded
        self.venue = venue
        self.golds = golds
        self.goldYears = goldYears
        self.finals = finals
        self.finalYears = finalYears
        self.retiredNumbers = retiredNumbers
        self.isActive = isActive
    }
}

// MARK: - Goalie Stats
public struct GoalieStats: Codable, Hashable {
    public let gamesPlayedIn: Int?
    public let wins: Int?
    public let losses: Int?
    public let ties: Int?
    public let shutouts: Int?
    public let saves: Int?
    public let goalsAgainst: Int?
    public let savePercentage: Double?
    public let goalsAgainstAverage: Double?

    public init(gamesPlayedIn: Int?, wins: Int?, losses: Int?, ties: Int?, shutouts: Int?, saves: Int?, goalsAgainst: Int?, savePercentage: Double?, goalsAgainstAverage: Double?) {
        self.gamesPlayedIn = gamesPlayedIn
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.shutouts = shutouts
        self.saves = saves
        self.goalsAgainst = goalsAgainst
        self.savePercentage = savePercentage
        self.goalsAgainstAverage = goalsAgainstAverage
    }
}

// MARK: - Advanced Stats
public struct AdvancedStats: Codable, Hashable {
    public let shotsOnGoal: Int?
    public let shootingPercentage: Double?
    public let powerPlayGoals: Int?
    public let powerPlayAssists: Int?
    public let shortHandedGoals: Int?
    public let shortHandedAssists: Int?
    public let gameWinningGoals: Int?
    public let overtimeGoals: Int?
    public let timeOnIce: Int?
    public let faceoffPercentage: Double?
    public let hits: Int?
    public let blockedShots: Int?

    public init(shotsOnGoal: Int?, shootingPercentage: Double?, powerPlayGoals: Int?, powerPlayAssists: Int?, shortHandedGoals: Int?, shortHandedAssists: Int?, gameWinningGoals: Int?, overtimeGoals: Int?, timeOnIce: Int?, faceoffPercentage: Double?, hits: Int?, blockedShots: Int?) {
        self.shotsOnGoal = shotsOnGoal
        self.shootingPercentage = shootingPercentage
        self.powerPlayGoals = powerPlayGoals
        self.powerPlayAssists = powerPlayAssists
        self.shortHandedGoals = shortHandedGoals
        self.shortHandedAssists = shortHandedAssists
        self.gameWinningGoals = gameWinningGoals
        self.overtimeGoals = overtimeGoals
        self.timeOnIce = timeOnIce
        self.faceoffPercentage = faceoffPercentage
        self.hits = hits
        self.blockedShots = blockedShots
    }
}

// MARK: - Player Game Log (Season Stats)
public struct PlayerGameLog: Codable, Identifiable, Hashable {
    public let id: String
    public let playerID: String
    public let season: SeasonDTO
    public let team: Team?
    public let gameType: GameType
    public let ssgtUUID: String?

    // Basic stats
    public let gamesPlayed: Int
    public let goals: Int
    public let assists: Int
    public let points: Int
    public let penaltyMinutes: Int
    public let plusMinus: Int?

    // Goalie stats (null for non-goalies)
    public let goalieStats: GoalieStats?

    // Advanced stats (optional)
    public let advancedStats: AdvancedStats?

    public init(id: String, playerID: String, season: SeasonDTO, team: Team?, gameType: GameType, ssgtUUID: String?, gamesPlayed: Int, goals: Int, assists: Int, points: Int, penaltyMinutes: Int, plusMinus: Int?, goalieStats: GoalieStats?, advancedStats: AdvancedStats?) {
        self.id = id
        self.playerID = playerID
        self.season = season
        self.team = team
        self.gameType = gameType
        self.ssgtUUID = ssgtUUID
        self.gamesPlayed = gamesPlayed
        self.goals = goals
        self.assists = assists
        self.points = points
        self.penaltyMinutes = penaltyMinutes
        self.plusMinus = plusMinus
        self.goalieStats = goalieStats
        self.advancedStats = advancedStats
    }
}

// MARK: - Convenience Extensions
extension PlayerGameLog {
    /// Check if this is a goalie stat record
    public var isGoalie: Bool {
        return goalieStats != nil
    }

    /// Get display name for game type
    public var gameTypeDisplayName: String {
        switch gameType {
        case .regular:
            return "Regular Season"
        case .playoff:
            return "Playoffs"
        }
    }
}

extension GoalieStats {
    /// Calculate games played safely
    public var gamesPlayedSafe: Int {
        return gamesPlayedIn ?? 0
    }

    /// Get formatted save percentage
    public var savePercentageFormatted: String {
        guard let pct = savePercentage else { return "N/A" }
        return String(format: "%.3f", pct)
    }

    /// Get formatted goals against average
    public var goalsAgainstAverageFormatted: String {
        guard let gaa = goalsAgainstAverage else { return "N/A" }
        return String(format: "%.2f", gaa)
    }
}

extension AdvancedStats {
    /// Get formatted shooting percentage
    public var shootingPercentageFormatted: String {
        guard let pct = shootingPercentage else { return "N/A" }
        return String(format: "%.1f%%", pct * 100)
    }

    /// Get formatted faceoff percentage
    public var faceoffPercentageFormatted: String {
        guard let pct = faceoffPercentage else { return "N/A" }
        return String(format: "%.1f%%", pct * 100)
    }
}
