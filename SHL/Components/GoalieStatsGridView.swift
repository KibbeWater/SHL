//
//  GoalieStatsGridView.swift
//  SHL
//
//  Created for goalie statistics display
//

import SwiftUI

struct GoalieStatsGridView: View {
    let title: String
    let gamesPlayed: Int
    let gamesPlayedIn: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let shutouts: Int
    let saves: Int
    let goalsAgainst: Int
    let savePercentage: Double?
    let goalsAgainstAverage: Double?

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
                StatItem(label: "GPI", value: "\(gamesPlayedIn)")

                StatItem(label: "W", value: "\(wins)")
                StatItem(label: "L", value: "\(losses)")
                StatItem(label: "T", value: "\(ties)")

                StatItem(label: "SO", value: "\(shutouts)")
                StatItem(label: "SVS", value: "\(saves)")
                StatItem(label: "GA", value: "\(goalsAgainst)")

                if let savePct = savePercentage {
                    StatItem(label: "SV%", value: String(format: "%.3f", savePct))
                }

                if let gaa = goalsAgainstAverage {
                    StatItem(label: "GAA", value: String(format: "%.2f", gaa))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            GoalieStatsGridView(
                title: "Career Totals",
                gamesPlayed: 250,
                gamesPlayedIn: 245,
                wins: 120,
                losses: 100,
                ties: 25,
                shutouts: 15,
                saves: 6500,
                goalsAgainst: 650,
                savePercentage: 0.909,
                goalsAgainstAverage: 2.65
            )

            GoalieStatsGridView(
                title: "2024/2025",
                gamesPlayed: 30,
                gamesPlayedIn: 28,
                wins: 15,
                losses: 10,
                ties: 3,
                shutouts: 2,
                saves: 780,
                goalsAgainst: 75,
                savePercentage: 0.912,
                goalsAgainstAverage: 2.68
            )
        }
        .padding()
    }
}
