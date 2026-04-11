//
//  iPadRoot.swift
//  SHL
//
//  iPad navigation shell using NavigationSplitView
//

import SwiftUI

struct iPadRoot: View {
    @State private var sidebarSelection: iPadSidebarItem? = .home
    @State private var detailRoute: iPadDetailRoute?
    @State private var teams: [Team] = []
    @State private var detailTeamColor: Color = .gray

    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var scheduleViewModel = MatchListViewModel()

    @StateObject private var navigationCoordinator = NavigationCoordinator.shared

    private let api = SHLAPIClient.shared

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
                .navigationTitle("SHL")
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            do {
                teams = try await api.getTeams()
            } catch {
                print("iPadRoot: Failed to fetch teams: \(error)")
            }
        }
        .onChange(of: navigationCoordinator.pendingMatchId) { _, newValue in
            guard let matchId = newValue else { return }
            handlePendingNavigation(matchId: matchId)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            Section {
                Label("Home", systemImage: "house")
                    .tag(iPadSidebarItem.home)

                Label("Schedule", systemImage: "calendar")
                    .tag(iPadSidebarItem.schedule)

                Label("Standings", systemImage: "list.number")
                    .tag(iPadSidebarItem.standings)
            }

            Section("Teams") {
                ForEach(teams) { team in
                    Label {
                        Text(team.name)
                    } icon: {
                        TeamLogoView(team: team, size: .custom(28))
                    }
                    .tag(iPadSidebarItem.team(team))
                }
            }

            Section {
                Label("Settings", systemImage: "gearshape")
                    .tag(iPadSidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Content Column

    @ViewBuilder
    private var contentColumn: some View {
        switch sidebarSelection {
        case .home:
            iPadHomeContent(
                viewModel: homeViewModel,
                onSelectMatch: { match in
                    detailRoute = .match(match)
                }
            )
            .navigationTitle("Home")
        case .schedule:
            iPadScheduleContent(
                viewModel: scheduleViewModel,
                onSelectMatch: { match in
                    detailRoute = .match(match)
                }
            )
            .navigationTitle("Schedule")
        case .standings:
            iPadStandingsContent(
                viewModel: homeViewModel,
                onSelectTeam: { team in
                    detailRoute = .team(team)
                }
            )
            .navigationTitle("Standings")
        case .team(let team):
            iPadTeamContent(
                team: team,
                onSelectMatch: { match in
                    detailRoute = .match(match)
                },
                onSelectPlayer: { player in
                    detailRoute = .player(player)
                }
            )
            .navigationTitle(team.name)
            .id(team.id)
        case .settings:
            SettingsView()
                .navigationTitle("Settings")
        case .none:
            Text("Select an item")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Detail Column

    @ViewBuilder
    private var detailColumn: some View {
        if let route = detailRoute {
            switch route {
            case .match(let match):
                MatchView(match, referrer: "ipad_detail")
            case .team(let team):
                TeamView(team: team)
            case .player(let player):
                PlayerView(player, teamColor: $detailTeamColor)
            }
        } else {
            ContentUnavailableView(
                "No Selection",
                systemImage: "sportscourt",
                description: Text("Select a match, team, or player to view details.")
            )
        }
    }

    // MARK: - Navigation

    private func handlePendingNavigation(matchId: String) {
        navigationCoordinator.clearPending()

        Task {
            guard let game = try? await api.getMatchDetail(id: matchId) else {
                print("iPadRoot: Unable to find game for navigation: \(matchId)")
                return
            }

            await MainActor.run {
                sidebarSelection = .home
                detailRoute = .match(game)
            }
        }
    }
}
