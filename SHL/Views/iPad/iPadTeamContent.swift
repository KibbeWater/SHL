//
//  iPadTeamContent.swift
//  SHL
//
//  iPad team content column with match history and player grid
//

import Kingfisher
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
        ScrollView {
            VStack(spacing: 20) {
                // Team header card
                teamHeader
                    .padding(.horizontal)

                // Matches section
                if !upcomingGames.isEmpty {
                    matchSection("Upcoming", matches: Array(upcomingGames))
                }

                if !playedGames.isEmpty {
                    matchSection("Recent Results", matches: Array(playedGames.prefix(8)))
                }

                // Lineup sections
                if !viewModel.lineup.isEmpty {
                    VStack(spacing: 16) {
                        if !goalkeepers.isEmpty {
                            playerGrid("Goalkeepers", players: goalkeepers)
                        }
                        if !defenders.isEmpty {
                            playerGrid("Defenders", players: defenders)
                        }
                        if !forwards.isEmpty {
                            playerGrid("Forwards", players: forwards)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            try? await viewModel.refresh()
        }
        .task {
            loadTeamColor()
        }
    }

    // MARK: - Team Header

    private var teamHeader: some View {
        HStack(spacing: 16) {
            TeamLogoView(team: team, size: .custom(72))
                .shadow(color: teamColor.opacity(0.3), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(team.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    if let rank = teamRank {
                        Label("#\(rank)", systemImage: "number")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    if let city = team.city {
                        Label(city, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let venue = team.venue {
                        Label(venue, systemImage: "building.2")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let golds = team.golds, golds > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("\(golds) championship\(golds == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(teamColor.opacity(0.1))
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Match Section

    private func matchSection(_ title: String, matches: [Match]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(matches.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            VStack(spacing: 8) {
                ForEach(matches) { match in
                    Button {
                        onSelectMatch(match)
                    } label: {
                        MatchCardCompact(game: match)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Player Grid

    private func playerGrid(_ title: String, players: [Player]) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(players.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                ForEach(players) { player in
                    Button {
                        onSelectPlayer(player)
                    } label: {
                        playerCard(player)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func playerCard(_ player: Player) -> some View {
        VStack(spacing: 6) {
            // Player portrait or fallback
            if let portraitURL = player.portraitURL, let url = URL(string: portraitURL) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(teamColor.opacity(0.3), lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(teamColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text("#\(player.jerseyNumber ?? 0)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(teamColor)
                }
            }

            VStack(spacing: 1) {
                Text(player.lastName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if player.portraitURL != nil {
                    Text("#\(player.jerseyNumber ?? 0)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func loadTeamColor() {
        team.getTeamColor { color in
            withAnimation(.easeInOut(duration: 0.3)) { teamColor = color }
        }
    }
}
