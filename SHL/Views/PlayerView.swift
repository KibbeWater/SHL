//
//  PlayerView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/9/24.
//

import HockeyKit
import Kingfisher
import SwiftUI

private enum PlayerTabs: String, CaseIterable {
    case statistics = "Statistics"
    case history = "History"
}

// MARK: - Stats Components

private struct StatItem: View {
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

private struct SkaterStatsGridView: View {
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

private struct GoalieStatsGridView: View {
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

// MARK: - Player View

struct PlayerView: View {
    @Environment(\.hockeyAPI) private var api: HockeyAPI
    
    @StateObject private var viewModel: PlayerViewModel

    let player: Player
    
    @Binding var teamColor: Color
    
    @State private var selectedTab: PlayerTabs = .statistics
    
    init(_ player: Player, teamColor: Binding<Color>) {
        self.player = player
        self._teamColor = teamColor
        self._viewModel = .init(wrappedValue: .init(player))
    }

    var statisticsTab: some View {
        VStack(spacing: 16) {
            if viewModel.stats.isEmpty {
                ProgressView()
                    .padding()
            } else if viewModel.isGoalie {
                // Goalie statistics
                let career = viewModel.careerTotalsGoalie
                let current = viewModel.currentSeasonTotalsGoalie

                GoalieStatsGridView(
                    title: "Career Totals",
                    gamesPlayed: career.gamesPlayed,
                    gamesPlayedIn: career.gamesPlayedIn,
                    wins: career.wins,
                    losses: career.losses,
                    ties: career.ties,
                    shutouts: career.shutouts,
                    saves: career.saves,
                    goalsAgainst: career.goalsAgainst,
                    savePercentage: floor((career.savePercentage ?? 0) * 100),
                    goalsAgainstAverage: career.goalsAgainstAverage
                )
                .padding(.horizontal)

                GoalieStatsGridView(
                    title: viewModel.currentSeasonName,
                    gamesPlayed: current.gamesPlayed,
                    gamesPlayedIn: current.gamesPlayedIn,
                    wins: current.wins,
                    losses: current.losses,
                    ties: current.ties,
                    shutouts: current.shutouts,
                    saves: current.saves,
                    goalsAgainst: current.goalsAgainst,
                    savePercentage: floor((career.savePercentage ?? 0) * 100),
                    goalsAgainstAverage: current.goalsAgainstAverage
                )
                .padding(.horizontal)
            } else {
                // Skater statistics
                let career = viewModel.careerTotalsSkater
                let current = viewModel.currentSeasonTotalsSkater

                SkaterStatsGridView(
                    title: "Career Totals",
                    gamesPlayed: career.gamesPlayed,
                    goals: career.goals,
                    assists: career.assists,
                    points: career.points,
                    pim: career.pim,
                    plusMinus: career.plusMinus,
                    shotsOnGoal: career.shotsOnGoal,
                    shootingPercentage: career.shootingPercentage,
                    powerPlayGoals: career.ppg,
                    shortHandedGoals: career.shg
                )
                .padding(.horizontal)

                SkaterStatsGridView(
                    title: viewModel.currentSeasonName,
                    gamesPlayed: current.gamesPlayed,
                    goals: current.goals,
                    assists: current.assists,
                    points: current.points,
                    pim: current.pim,
                    plusMinus: current.plusMinus,
                    shotsOnGoal: current.shotsOnGoal,
                    shootingPercentage: current.shootingPercentage,
                    powerPlayGoals: current.ppg,
                    shortHandedGoals: current.shg
                )
                .padding(.horizontal)
            }
        }
    }
    
    func seasonStatsRow(stat: PlayerGameLog) -> some View {
        HStack {
            VStack {
                if let team = stat.team {
                    TeamLogoView(team: team, size: .mediumSmall)
                } else {
                    Image(systemName: "hockey.puck")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 46, height: 46)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stat.team?.name ?? "Unknown Team")
                        .fontWeight(.semibold)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(stat.gameTypeDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(stat.season.series.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    if viewModel.isGoalie {
                        if let goalieStats = stat.goalieStats {
                            Text("\(goalieStats.wins ?? 0)W \(goalieStats.losses ?? 0)L \(goalieStats.ties ?? 0)T")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f SV%%", (goalieStats.savePercentage ?? 0) * 100))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("\(stat.goals)G \(stat.assists)A \(stat.points)P")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(stat.gamesPlayed) GP")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .frame(height: 52)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var historyTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.stats.isEmpty {
                ProgressView()
                    .padding()
            } else {
                ForEach(viewModel.statsGroupedBySeason, id: \.season.id) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(group.season.name)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)

                        VStack(spacing: 12) {
                            ForEach(group.stats.sorted(by: { $0.gameType.rawValue < $1.gameType.rawValue }), id: \.id) { stat in
                                seasonStatsRow(stat: stat)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                teamColor,
                .clear,
                .clear,
            ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        Text(player.fullName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        HStack {
                            Text(String(player.jerseyNumber ?? -1))
                                .font(.title3)
                                .fontWeight(.medium)
                                .frame(height: 22)
                            if let info = viewModel.info {
                                switch info.position {
                                case .goalkeeper:
                                    Text("Goalkeeper")
                                        .fontWeight(.medium)
                                case .defense:
                                    Text("Defense")
                                        .fontWeight(.medium)
                                case .forward:
                                    Text("Forward")
                                        .fontWeight(.medium)
                                case .none:
                                    Text("None")
                                        .fontWeight(.medium)
                                }
                            } else {
                                ProgressView()
                            }
                            Divider()
                                .frame(height: 22)
                            if let info = viewModel.info, let team = info.team {
                                TeamLogoView(team: team, size: .extraSmall)
                                Text(team.name)
                            } else {
                                ProgressView()
                            }
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if let info = viewModel.info, let imageUrl = info.portraitURL {
                        KFImage(.init(string: imageUrl)!)
                            .placeholder {
                                ProgressView()
                                    .frame(width: 72, height: 72)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 72)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                
                VStack {
                    HStack {
                        Spacer()
                        ForEach(PlayerTabs.allCases, id: \.self) { tab in
                            Button(tab.rawValue) {
                                selectedTab = tab
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .buttonStyle(.plain)
                            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                            Spacer()
                        }
                    }
                    
                    VStack {
                        switch selectedTab {
                        case .statistics:
                            statisticsTab
                        case .history:
                            historyTab
                        }
                    }
                    .padding(.top)
                }
                .padding(.top, 52)
            }
            .refreshable {
                try? await viewModel.refresh()
            }
        }
        .onAppear {
            Task {
                try? await viewModel.refresh()
            }
        }
    }
}

#Preview {
    PlayerView(.fakeData(), teamColor: .constant(.black))
}
