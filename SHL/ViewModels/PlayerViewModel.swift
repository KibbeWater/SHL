//
//  PlayerViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit
import SwiftUI

@MainActor
class PlayerViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private var player: Player

    @Published var info: Player? = nil
    @Published var stats: [PlayerGameLog] = []

    init(_ player: Player) {
        self.player = player

        Task {
            try? await refresh()
        }
    }

    func refresh() async throws {
        self.info = try await api.getPlayerDetail(id: player.id)
        if let info {
            self.stats = (try? await api.getPlayerStats(id: info.id)) ?? []
        }
    }

    // MARK: - Computed Properties for Stats

    /// Check if the player is a goalie based on position
    var isGoalie: Bool {
        return info?.position == .goalkeeper || stats.first?.isGoalie == true
    }

    /// Get stats for the current season (combined regular + playoff)
    var currentSeasonStats: [PlayerGameLog] {
        return stats.filter { $0.season.isCurrent }
    }

    /// Get stats grouped by season
    var statsBySeason: [String: [PlayerGameLog]] {
        return Dictionary(grouping: stats) { $0.season.id }
    }

    /// Get stats grouped and sorted by season (most recent first)
    var statsGroupedBySeason: [(season: SeasonDTO, stats: [PlayerGameLog])] {
        let grouped = Dictionary(grouping: stats) { $0.season }
        return grouped.map { (season: $0.key, stats: $0.value) }
            .sorted { $0.season.isCurrent || ($0.season.startDate ?? Date.distantPast) > ($1.season.startDate ?? Date.distantPast) }
    }

    /// Calculate career totals for skaters
    var careerTotalsSkater: (gamesPlayed: Int, goals: Int, assists: Int, points: Int, pim: Int, plusMinus: Int, shotsOnGoal: Int, shootingPercentage: Double?, ppg: Int, shg: Int) {
        let totalGP = stats.reduce(0) { $0 + $1.gamesPlayed }
        let totalGoals = stats.reduce(0) { $0 + $1.goals }
        let totalAssists = stats.reduce(0) { $0 + $1.assists }
        let totalPoints = stats.reduce(0) { $0 + $1.points }
        let totalPIM = stats.reduce(0) { $0 + $1.penaltyMinutes }
        let totalPlusMinus = stats.reduce(0) { $0 + ($1.plusMinus ?? 0) }
        let totalSOG = stats.reduce(0) { $0 + ($1.advancedStats?.shotsOnGoal ?? 0) }
        let totalPPG = stats.reduce(0) { $0 + ($1.advancedStats?.powerPlayGoals ?? 0) }
        let totalSHG = stats.reduce(0) { $0 + ($1.advancedStats?.shortHandedGoals ?? 0) }

        let shootingPct = totalSOG > 0 ? Double(totalGoals) / Double(totalSOG) : nil

        return (totalGP, totalGoals, totalAssists, totalPoints, totalPIM, totalPlusMinus, totalSOG, shootingPct, totalPPG, totalSHG)
    }

    /// Calculate career totals for goalies
    var careerTotalsGoalie: (gamesPlayed: Int, gamesPlayedIn: Int, wins: Int, losses: Int, ties: Int, shutouts: Int, saves: Int, goalsAgainst: Int, savePercentage: Double?, goalsAgainstAverage: Double?) {
        let totalGP = stats.reduce(0) { $0 + $1.gamesPlayed }
        let totalGPI = stats.reduce(0) { $0 + ($1.goalieStats?.gamesPlayedIn ?? 0) }
        let totalWins = stats.reduce(0) { $0 + ($1.goalieStats?.wins ?? 0) }
        let totalLosses = stats.reduce(0) { $0 + ($1.goalieStats?.losses ?? 0) }
        let totalTies = stats.reduce(0) { $0 + ($1.goalieStats?.ties ?? 0) }
        let totalShutouts = stats.reduce(0) { $0 + ($1.goalieStats?.shutouts ?? 0) }
        let totalSaves = stats.reduce(0) { $0 + ($1.goalieStats?.saves ?? 0) }
        let totalGA = stats.reduce(0) { $0 + ($1.goalieStats?.goalsAgainst ?? 0) }

        let savePct = (totalSaves + totalGA) > 0 ? Double(totalSaves) / Double(totalSaves + totalGA) : nil
        let gaa = totalGPI > 0 ? Double(totalGA) / Double(totalGPI) : nil

        return (totalGP, totalGPI, totalWins, totalLosses, totalTies, totalShutouts, totalSaves, totalGA, savePct, gaa)
    }

    /// Calculate current season totals for skaters
    var currentSeasonTotalsSkater: (gamesPlayed: Int, goals: Int, assists: Int, points: Int, pim: Int, plusMinus: Int, shotsOnGoal: Int, shootingPercentage: Double?, ppg: Int, shg: Int) {
        let currentStats = currentSeasonStats
        let totalGP = currentStats.reduce(0) { $0 + $1.gamesPlayed }
        let totalGoals = currentStats.reduce(0) { $0 + $1.goals }
        let totalAssists = currentStats.reduce(0) { $0 + $1.assists }
        let totalPoints = currentStats.reduce(0) { $0 + $1.points }
        let totalPIM = currentStats.reduce(0) { $0 + $1.penaltyMinutes }
        let totalPlusMinus = currentStats.reduce(0) { $0 + ($1.plusMinus ?? 0) }
        let totalSOG = currentStats.reduce(0) { $0 + ($1.advancedStats?.shotsOnGoal ?? 0) }
        let totalPPG = currentStats.reduce(0) { $0 + ($1.advancedStats?.powerPlayGoals ?? 0) }
        let totalSHG = currentStats.reduce(0) { $0 + ($1.advancedStats?.shortHandedGoals ?? 0) }

        let shootingPct = totalSOG > 0 ? Double(totalGoals) / Double(totalSOG) : nil

        return (totalGP, totalGoals, totalAssists, totalPoints, totalPIM, totalPlusMinus, totalSOG, shootingPct, totalPPG, totalSHG)
    }

    /// Calculate current season totals for goalies
    var currentSeasonTotalsGoalie: (gamesPlayed: Int, gamesPlayedIn: Int, wins: Int, losses: Int, ties: Int, shutouts: Int, saves: Int, goalsAgainst: Int, savePercentage: Double?, goalsAgainstAverage: Double?) {
        let currentStats = currentSeasonStats
        let totalGP = currentStats.reduce(0) { $0 + $1.gamesPlayed }
        let totalGPI = currentStats.reduce(0) { $0 + ($1.goalieStats?.gamesPlayedIn ?? 0) }
        let totalWins = currentStats.reduce(0) { $0 + ($1.goalieStats?.wins ?? 0) }
        let totalLosses = currentStats.reduce(0) { $0 + ($1.goalieStats?.losses ?? 0) }
        let totalTies = currentStats.reduce(0) { $0 + ($1.goalieStats?.ties ?? 0) }
        let totalShutouts = currentStats.reduce(0) { $0 + ($1.goalieStats?.shutouts ?? 0) }
        let totalSaves = currentStats.reduce(0) { $0 + ($1.goalieStats?.saves ?? 0) }
        let totalGA = currentStats.reduce(0) { $0 + ($1.goalieStats?.goalsAgainst ?? 0) }

        let savePct = (totalSaves + totalGA) > 0 ? Double(totalSaves) / Double(totalSaves + totalGA) : nil
        let gaa = totalGPI > 0 ? Double(totalGA) / Double(totalGPI) : nil

        return (totalGP, totalGPI, totalWins, totalLosses, totalTies, totalShutouts, totalSaves, totalGA, savePct, gaa)
    }

    /// Get current season name for display
    var currentSeasonName: String {
        return currentSeasonStats.first?.season.name ?? "N/A"
    }
}
