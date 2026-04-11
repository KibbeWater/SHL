//
//  iPadTeamContent.swift
//  SHL
//
//  iPad team content column with match history and player grid
//

import SwiftUI

struct iPadTeamContent: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    let team: Team
    var onSelectMatch: (Match) -> Void
    var onSelectPlayer: (Player) -> Void

    @StateObject private var viewModel: TeamViewModel
    @State private var teamColor: Color = .gray

    init(team: Team, onSelectMatch: @escaping (Match) -> Void, onSelectPlayer: @escaping (Player) -> Void) {
        self.team = team
        self.onSelectMatch = onSelectMatch
        self.onSelectPlayer = onSelectPlayer
        self._viewModel = .init(wrappedValue: .init(team))
    }

    private var upcomingGames: [Match] {
        viewModel.history.filter { !$0.concluded }.reversed()
    }

    private var playedGames: [Match] {
        viewModel.history.filter { $0.concluded }
    }

    private var teamRank: Int? {
        viewModel.standings.first(where: { $0.team.code == team.code })?.rank
    }

    private var goalkeepers: [Player] {
        viewModel.lineup.filter { $0.position == .goalkeeper }
    }

    private var defenders: [Player] {
        viewModel.lineup.filter { $0.position == .defense }
    }

    private var forwards: [Player] {
        viewModel.lineup.filter { $0.position == .forward }
    }

    var body: some View {
        List {
            // Team header
            Section {
                HStack(spacing: 16) {
                    TeamLogoView(team: team, size: .custom(64))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let rank = teamRank {
                            Text("Rank #\(rank)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let city = team.city {
                            Text(city)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // Upcoming games
            if !upcomingGames.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingGames) { match in
                        Button {
                            onSelectMatch(match)
                        } label: {
                            MatchOverview(game: match)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }

            // Recent results
            if !playedGames.isEmpty {
                Section("Recent Results") {
                    ForEach(playedGames.prefix(10)) { match in
                        Button {
                            onSelectMatch(match)
                        } label: {
                            MatchOverview(game: match)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }

            // Lineup
            if !viewModel.lineup.isEmpty {
                playerSection("Goalkeepers", players: goalkeepers)
                playerSection("Defenders", players: defenders)
                playerSection("Forwards", players: forwards)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            try? await viewModel.refresh()
        }
    }

    private func playerSection(_ title: String, players: [Player]) -> some View {
        Section(title) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                ForEach(players) { player in
                    Button {
                        onSelectPlayer(player)
                    } label: {
                        VStack(spacing: 8) {
                            TeamLogoView(teamCode: team.code, size: .custom(40))

                            VStack(spacing: 2) {
                                Text("#\(player.jerseyNumber ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(player.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
}
