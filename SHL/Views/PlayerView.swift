//
//  PlayerView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/9/24.
//

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
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatRow: View {
    let items: [(label: String, value: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                StatItem(label: item.label, value: item.value)
            }
        }
    }
}

// MARK: - Player View

struct PlayerView: View {
    @StateObject private var viewModel: PlayerViewModel

    let player: Player
    @Binding var teamColor: Color

    @State private var selectedTab: PlayerTabs = .statistics

    init(_ player: Player, teamColor: Binding<Color>) {
        self.player = player
        self._teamColor = teamColor
        self._viewModel = .init(wrappedValue: .init(player))
    }

    // MARK: - Computed Properties

    private var positionText: String {
        guard let info = viewModel.info else { return "" }
        switch info.position {
        case .goalkeeper: return "Goalkeeper"
        case .defense: return "Defense"
        case .forward: return "Forward"
        case .none: return ""
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    tabPicker

                    contentSection
                }
                .padding(.bottom, 32)
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

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [teamColor, teamColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.clear, Color(uiColor: .systemBackground)],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Player Image
            playerImage

            // Player Info
            VStack(spacing: 8) {
                Text(player.fullName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    if let number = player.jerseyNumber {
                        playerInfoBadge(text: "#\(number)", icon: nil)
                    }

                    if !positionText.isEmpty {
                        playerInfoBadge(text: positionText, icon: "figure.hockey")
                    }

                    if let info = viewModel.info, let team = info.team {
                        NavigationLink {
                            TeamView(team: team)
                        } label: {
                            HStack(spacing: 6) {
                                TeamLogoView(team: team, size: .extraSmall)
                                Text(team.code)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    private var playerImage: some View {
        Group {
            if let info = viewModel.info, let imageUrl = info.portraitURL {
                KFImage(URL(string: imageUrl))
                    .placeholder {
                        playerImagePlaceholder
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            } else {
                playerImagePlaceholder
            }
        }
    }

    private var playerImagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 150)

            if viewModel.info == nil {
                ProgressView()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private func playerInfoBadge(text: String, icon: String?) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(PlayerTabs.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        switch selectedTab {
        case .statistics:
            statisticsContent
        case .history:
            historyContent
        }
    }

    // MARK: - Statistics Content

    private var statisticsContent: some View {
        VStack(spacing: 16) {
            if viewModel.stats.isEmpty {
                loadingStateView
            } else if viewModel.isGoalie {
                goalieStatsCards
            } else {
                skaterStatsCards
            }
        }
        .padding(.horizontal)
    }

    private var skaterStatsCards: some View {
        VStack(spacing: 16) {
            // Career Stats
            let career = viewModel.careerTotalsSkater
            statsCard(
                title: "Career Totals",
                icon: "chart.bar.fill"
            ) {
                skaterStatsGrid(
                    gamesPlayed: career.gamesPlayed,
                    goals: career.goals,
                    assists: career.assists,
                    points: career.points,
                    pim: career.pim,
                    plusMinus: career.plusMinus,
                    shotsOnGoal: career.shotsOnGoal,
                    shootingPercentage: career.shootingPercentage,
                    ppg: career.ppg,
                    shg: career.shg
                )
            }

            // Current Season Stats
            let current = viewModel.currentSeasonTotalsSkater
            statsCard(
                title: viewModel.currentSeasonName,
                icon: "calendar"
            ) {
                skaterStatsGrid(
                    gamesPlayed: current.gamesPlayed,
                    goals: current.goals,
                    assists: current.assists,
                    points: current.points,
                    pim: current.pim,
                    plusMinus: current.plusMinus,
                    shotsOnGoal: current.shotsOnGoal,
                    shootingPercentage: current.shootingPercentage,
                    ppg: current.ppg,
                    shg: current.shg
                )
            }
        }
    }

    private func skaterStatsGrid(
        gamesPlayed: Int, goals: Int, assists: Int, points: Int,
        pim: Int, plusMinus: Int, shotsOnGoal: Int,
        shootingPercentage: Double?, ppg: Int, shg: Int
    ) -> some View {
        VStack(spacing: 16) {
            StatRow(items: [
                ("GP", "\(gamesPlayed)"),
                ("G", "\(goals)"),
                ("A", "\(assists)")
            ])

            StatRow(items: [
                ("P", "\(points)"),
                ("PIM", "\(pim)"),
                ("+/-", plusMinus >= 0 ? "+\(plusMinus)" : "\(plusMinus)")
            ])

            if shotsOnGoal > 0 || shootingPercentage != nil || ppg > 0 {
                Divider()

                StatRow(items: [
                    ("SOG", "\(shotsOnGoal)"),
                    ("S%", shootingPercentage.map { String(format: "%.1f%%", $0 * 100) } ?? "-"),
                    ("PPG", "\(ppg)")
                ])
            }

            if shg > 0 {
                StatRow(items: [
                    ("SHG", "\(shg)"),
                    ("", ""),
                    ("", "")
                ])
            }
        }
    }

    private var goalieStatsCards: some View {
        VStack(spacing: 16) {
            // Career Stats
            let career = viewModel.careerTotalsGoalie
            statsCard(
                title: "Career Totals",
                icon: "chart.bar.fill"
            ) {
                goalieStatsGrid(
                    gamesPlayed: career.gamesPlayed,
                    gamesPlayedIn: career.gamesPlayedIn,
                    wins: career.wins,
                    losses: career.losses,
                    ties: career.ties,
                    shutouts: career.shutouts,
                    saves: career.saves,
                    goalsAgainst: career.goalsAgainst,
                    savePercentage: career.savePercentage,
                    goalsAgainstAverage: career.goalsAgainstAverage
                )
            }

            // Current Season Stats
            let current = viewModel.currentSeasonTotalsGoalie
            statsCard(
                title: viewModel.currentSeasonName,
                icon: "calendar"
            ) {
                goalieStatsGrid(
                    gamesPlayed: current.gamesPlayed,
                    gamesPlayedIn: current.gamesPlayedIn,
                    wins: current.wins,
                    losses: current.losses,
                    ties: current.ties,
                    shutouts: current.shutouts,
                    saves: current.saves,
                    goalsAgainst: current.goalsAgainst,
                    savePercentage: current.savePercentage,
                    goalsAgainstAverage: current.goalsAgainstAverage
                )
            }
        }
    }

    private func goalieStatsGrid(
        gamesPlayed: Int, gamesPlayedIn: Int, wins: Int, losses: Int,
        ties: Int, shutouts: Int, saves: Int, goalsAgainst: Int,
        savePercentage: Double?, goalsAgainstAverage: Double?
    ) -> some View {
        VStack(spacing: 16) {
            StatRow(items: [
                ("GP", "\(gamesPlayed)"),
                ("GPI", "\(gamesPlayedIn)"),
                ("W", "\(wins)")
            ])

            StatRow(items: [
                ("L", "\(losses)"),
                ("T", "\(ties)"),
                ("SO", "\(shutouts)")
            ])

            Divider()

            StatRow(items: [
                ("SVS", "\(saves)"),
                ("GA", "\(goalsAgainst)"),
                ("SV%", savePercentage.map { String(format: "%.3f", $0) } ?? "-")
            ])

            if let gaa = goalsAgainstAverage {
                StatRow(items: [
                    ("GAA", String(format: "%.2f", gaa)),
                    ("", ""),
                    ("", "")
                ])
            }
        }
    }

    private func statsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            content()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History Content

    private var historyContent: some View {
        VStack(spacing: 16) {
            if viewModel.stats.isEmpty {
                loadingStateView
            } else {
                ForEach(viewModel.statsGroupedBySeason, id: \.season.id) { group in
                    seasonSection(season: group.season, stats: group.stats)
                }
            }
        }
        .padding(.horizontal)
    }

    private func seasonSection(season: SeasonDTO, stats: [PlayerGameLog]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(season.name, systemImage: "calendar")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(stats.sorted(by: { $0.gameType.rawValue < $1.gameType.rawValue }), id: \.id) { stat in
                    seasonStatsRow(stat: stat)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func seasonStatsRow(stat: PlayerGameLog) -> some View {
        HStack(spacing: 12) {
            // Team Logo
            if let team = stat.team {
                TeamLogoView(team: team, size: .mediumSmall)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(width: 46, height: 46)
                    Image(systemName: "hockey.puck")
                        .foregroundStyle(.secondary)
                }
            }

            // Team Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stat.team?.name ?? "Unknown Team")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(stat.season.series.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    Text(stat.gameTypeDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    if viewModel.isGoalie {
                        if let goalieStats = stat.goalieStats {
                            Text("\(goalieStats.wins ?? 0)W \(goalieStats.losses ?? 0)L")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let svPct = goalieStats.savePercentage {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f SV%%", svPct * 100))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("\(stat.goals)G \(stat.assists)A \(stat.points)P")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text("\(stat.gamesPlayed) GP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Loading State

    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlayerView(.fakeData(), teamColor: .constant(.blue))
    }
}
