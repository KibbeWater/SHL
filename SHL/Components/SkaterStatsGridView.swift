//
//  SkaterStatsGridView.swift
//  SHL
//
//  Created for player statistics display
//

import SwiftUI

struct SkaterStatsGridView: View {
    let title: String
    let gamesPlayed: Int
    let goals: Int
    let assists: Int
    let points: Int
    let pim: Int
    let plusMinus: Int
    let shotsOnGoal: Int
    let shootingPercentage: Double?
    let powerPlayGoals: Int
    let shortHandedGoals: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(label: "GP", value: "\(gamesPlayed)")
                StatItem(label: "G", value: "\(goals)")
                StatItem(label: "A", value: "\(assists)")
                StatItem(label: "P", value: "\(points)")
                StatItem(label: "PIM", value: "\(pim)")
                StatItem(label: "+/-", value: plusMinus >= 0 ? "+\(plusMinus)" : "\(plusMinus)")

                if shotsOnGoal > 0 {
                    StatItem(label: "SOG", value: "\(shotsOnGoal)")
                }

                if let shootingPct = shootingPercentage {
                    StatItem(label: "S%", value: String(format: "%.1f%%", shootingPct * 100))
                }

                if powerPlayGoals > 0 {
                    StatItem(label: "PPG", value: "\(powerPlayGoals)")
                }

                if shortHandedGoals > 0 {
                    StatItem(label: "SHG", value: "\(shortHandedGoals)")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SkaterStatsGridView(
                title: "Career Totals",
                gamesPlayed: 500,
                goals: 150,
                assists: 200,
                points: 350,
                pim: 100,
                plusMinus: 45,
                shotsOnGoal: 1200,
                shootingPercentage: 0.125,
                powerPlayGoals: 40,
                shortHandedGoals: 5
            )

            SkaterStatsGridView(
                title: "2024/2025",
                gamesPlayed: 45,
                goals: 18,
                assists: 22,
                points: 40,
                pim: 24,
                plusMinus: 12,
                shotsOnGoal: 150,
                shootingPercentage: 0.12,
                powerPlayGoals: 5,
                shortHandedGoals: 1
            )
        }
        .padding()
    }
}
