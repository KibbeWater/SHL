//
//  PlayerGameLog.swift
//  SHL
//
//  Created by Migration Script
//  Updated to match backend PlayerStatDTO structure
//

import Foundation

// MARK: - Game Type Enum
enum GameType: String, Codable {
    case regular
    case playoff
}

// MARK: - Series DTO
struct SeriesDTO: Codable, Hashable {
    let id: String
    let code: String
    let name: String
    let externalUUID: String
    let gender: String?
    let country: String
    let priority: Int
    let isActive: Bool
}

// MARK: - Season DTO
struct SeasonDTO: Codable, Hashable {
    let id: String
    let series: SeriesDTO
    let externalUUID: String
    let code: String
    let name: String
    let startDate: Date?
    let endDate: Date?
    let isCurrent: Bool
}

// MARK: - Team DTO (for stats)
struct StatTeamDTO: Codable, Hashable {
    let id: String
    let externalId: String?
    let name: String
    let code: String
    let city: String?
    let founded: Int?
    let venue: String?
    let golds: Int?
    let goldYears: [Int]?
    let finals: Int?
    let finalYears: [Int]?
    let retiredNumbers: [String]?
    let isActive: Bool
}

// MARK: - Goalie Stats
struct GoalieStats: Codable, Hashable {
    let gamesPlayedIn: Int?
    let wins: Int?
    let losses: Int?
    let ties: Int?
    let shutouts: Int?
    let saves: Int?
    let goalsAgainst: Int?
    let savePercentage: Double?
    let goalsAgainstAverage: Double?
}

// MARK: - Advanced Stats
struct AdvancedStats: Codable, Hashable {
    let shotsOnGoal: Int?
    let shootingPercentage: Double?
    let powerPlayGoals: Int?
    let powerPlayAssists: Int?
    let shortHandedGoals: Int?
    let shortHandedAssists: Int?
    let gameWinningGoals: Int?
    let overtimeGoals: Int?
    let timeOnIce: Int?
    let faceoffPercentage: Double?
    let hits: Int?
    let blockedShots: Int?
}

// MARK: - Player Game Log (Season Stats)
struct PlayerGameLog: Codable, Identifiable, Hashable {
    let id: String
    let playerID: String
    let season: SeasonDTO
    let team: Team?
    let gameType: GameType
    let ssgtUUID: String?

    // Basic stats
    let gamesPlayed: Int
    let goals: Int
    let assists: Int
    let points: Int
    let penaltyMinutes: Int
    let plusMinus: Int?

    // Goalie stats (null for non-goalies)
    let goalieStats: GoalieStats?

    // Advanced stats (optional)
    let advancedStats: AdvancedStats?
}

// MARK: - Convenience Extensions
extension PlayerGameLog {
    /// Check if this is a goalie stat record
    var isGoalie: Bool {
        return goalieStats != nil
    }

    /// Get display name for game type
    var gameTypeDisplayName: String {
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
    var gamesPlayedSafe: Int {
        return gamesPlayedIn ?? 0
    }

    /// Get formatted save percentage
    var savePercentageFormatted: String {
        guard let pct = savePercentage else { return "N/A" }
        return String(format: "%.3f", pct)
    }

    /// Get formatted goals against average
    var goalsAgainstAverageFormatted: String {
        guard let gaa = goalsAgainstAverage else { return "N/A" }
        return String(format: "%.2f", gaa)
    }
}

extension AdvancedStats {
    /// Get formatted shooting percentage
    var shootingPercentageFormatted: String {
        guard let pct = shootingPercentage else { return "N/A" }
        return String(format: "%.1f%%", pct * 100)
    }

    /// Get formatted faceoff percentage
    var faceoffPercentageFormatted: String {
        guard let pct = faceoffPercentage else { return "N/A" }
        return String(format: "%.1f%%", pct * 100)
    }
}
