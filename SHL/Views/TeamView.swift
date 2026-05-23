//
//  TeamView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 28/9/24.
//

import Kingfisher
import SwiftUI

private enum TeamTabs: String, CaseIterable {
    case history = "History"
    case lineup = "Lineup"
}

struct TeamView: View {
    @StateObject var viewModel: TeamViewModel

    @State private var teamColor: Color = .gray
    @State private var selectedTab: TeamTabs = .history
    @State private var refreshTick = 0

    let team: Team

    init(team: Team) {
        self.team = team
        self._viewModel = .init(wrappedValue: .init(team))
    }

    // MARK: - Computed Properties

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
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 32)
            }
            .refreshable {
                try? await viewModel.refresh()
                refreshTick &+= 1
            }
        }
        .task {
            loadTeamColors()
        }
        .onAppear {
            Task {
                try? await viewModel.refresh()
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.success, trigger: refreshTick)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [teamColor, teamColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Scrim for white-text contrast on bright team colors.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.5), location: 0),
                    .init(color: .black.opacity(0.3), location: 0.25),
                    .init(color: .black.opacity(0.1), location: 0.55),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .center
            )

            LinearGradient(
                colors: [.clear, Color(uiColor: .systemBackground)],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.5), value: teamColor)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 14) {
            TeamLogoView(team: team, size: .custom(100))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 6)

            VStack(spacing: 8) {
                Text(team.name)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
                    .multilineTextAlignment(.center)

                if let rank = teamRank {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                        Text("#\(rank) in standings")
                            .font(.subheadline.weight(.medium))
                            .contentTransition(.numericText(value: Double(rank)))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: .capsule)
                    .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(TeamTabs.allCases, id: \.self) { tab in
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
        case .history:
            matchHistoryContent
                .transition(.opacity.combined(with: .move(edge: .leading)))
        case .lineup:
            lineupContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    // MARK: - Match History Content

    private var matchHistoryContent: some View {
        VStack(spacing: 16) {
            if viewModel.history.isEmpty {
                loadingStateView
            } else {
                if !upcomingGames.isEmpty {
                    matchSection(
                        title: "Upcoming Games",
                        icon: "calendar",
                        matches: Array(upcomingGames.prefix(5))
                    )
                }

                if !playedGames.isEmpty {
                    matchSection(
                        title: "Recent Results",
                        icon: "clock.arrow.circlepath",
                        matches: Array(playedGames.prefix(10))
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    private func matchSection(title: String, icon: String, matches: [Match]) -> some View {
        VStack(spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline.weight(.semibold))
                Spacer()
            }

            LazyVStack(spacing: 10) {
                ForEach(matches, id: \.id) { match in
                    NavigationLink {
                        MatchView(match, referrer: "team_view")
                    } label: {
                        MatchOverview(game: match)
                    }
                    .buttonStyle(.scalePress)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Lineup Content

    private var lineupContent: some View {
        VStack(spacing: 16) {
            if viewModel.lineup.isEmpty {
                loadingStateView
            } else {
                if !goalkeepers.isEmpty {
                    playerSection(
                        title: "Goalkeepers",
                        icon: "person.fill.checkmark",
                        players: goalkeepers
                    )
                }

                if !defenders.isEmpty {
                    playerSection(
                        title: "Defenders",
                        icon: "shield.fill",
                        players: defenders
                    )
                }

                if !forwards.isEmpty {
                    playerSection(
                        title: "Forwards",
                        icon: "figure.hockey",
                        players: forwards
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    private func playerSection(title: String, icon: String, players: [Player]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline.weight(.semibold))
                Spacer()
                Text("\(players.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: .capsule)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(players, id: \.id) { player in
                        playerCard(player)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func playerCard(_ player: Player) -> some View {
        NavigationLink {
            PlayerView(player, teamColor: $teamColor)
        } label: {
            VStack(spacing: 0) {
                if let url = player.portraitURL, let imageURL = URL(string: url) {
                    KFImage(imageURL)
                        .placeholder {
                            playerPlaceholder
                        }
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 160, height: 200)))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 150)
                        .background(playerCountryGradient(player))
                        .clipped()
                } else {
                    playerPlaceholder
                        .frame(width: 120, height: 150)
                }

                VStack(spacing: 4) {
                    Text(player.fullName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let number = player.jerseyNumber {
                        Text("#\(number)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(width: 120)
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.scalePress)
    }

    private var playerPlaceholder: some View {
        ZStack {
            Color(uiColor: .tertiarySystemFill)
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
    }

    private func playerCountryGradient(_ player: Player) -> LinearGradient {
        switch player.nationality {
        case .sweden:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .top, endPoint: .bottom)
        case .finland:
            return LinearGradient(colors: [.white, .blue], startPoint: .top, endPoint: .bottom)
        case .canada:
            return LinearGradient(colors: [.red, .white], startPoint: .top, endPoint: .bottom)
        case .usa:
            return LinearGradient(colors: [.red, .blue], startPoint: .top, endPoint: .bottom)
        case .norway:
            return LinearGradient(colors: [.red, .white, .blue], startPoint: .top, endPoint: .bottom)
        case .none, .unknown:
            return LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: - Loading State

    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Actions

    private func loadTeamColors() {
        team.getTeamColor { color in
            withAnimation(.smooth(duration: 0.4)) {
                teamColor = color
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TeamView(team: .fakeData())
    }
}

#Preview("Dark") {
    NavigationStack {
        TeamView(team: .fakeData())
    }
    .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    NavigationStack {
        TeamView(team: .fakeData())
    }
}
