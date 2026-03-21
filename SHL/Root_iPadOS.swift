//
//  Root_iPadOS.swift
//  SHL
//
//  iPad-specific root layout — sidebar with team tabs
//

import SHLCore
import SHLNetwork
import SwiftUI

struct Root_iPadOS: View {
    @State private var loggedIn = false
    @State private var showOnboarding = false

    private let api = SHLAPIClient.shared

    @State private var openedGame: MatchView?
    @State private var isGameOpen = false

    @State private var selectedTab: RootTabs = .home
    @State private var teams: [Team] = []

    @StateObject private var navigationCoordinator = NavigationCoordinator.shared

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house", value: .home) {
                    NavigationStack {
                        HomeView()
                            .navigationDestination(isPresented: $isGameOpen) {
                                openedGame
                            }
                    }
                }

                Tab("Schedule", systemImage: "calendar", value: RootTabs.calendar) {
                    NavigationStack {
                        MatchListView()
                    }
                }

                Tab("Settings", systemImage: "gearshape", value: RootTabs.settings) {
                    NavigationStack {
                        SettingsView()
                    }
                }

                #if DEBUG
                if #available(iOS 26.0, *) {
                    Tab(value: RootTabs.search, role: .search) {
                        SearchView()
                    }
                }
                #endif

                TabSection("Teams") {
                    ForEach(teams, id: \.id) { team in
                        Tab(value: RootTabs.team(team)) {
                            TeamView(team: team)
                        } label: {
                            HStack {
                                if let img = svgToImage(named: "Team/\(team.code.uppercased())", width: 28) {
                                    img
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    Text(team.name)
                                } else {
                                    EmptyView()
                                }
                            }
                            .frame(height: 32)
                        }
                    }
                }
                .defaultVisibility(.hidden, for: .tabBar)
            }
            .tabViewStyle(.sidebarAdaptable)

            if !loggedIn {
                splashScreen
            }
        }
        .task { await loadTeams() }
        .onAppear { Task { await ReminderContext.refreshActiveReminders() } }
        .onOpenURL { handleIncomingURL($0) }
        .onChange(of: navigationCoordinator.pendingMatchId) { _, newValue in
            guard let matchId = newValue else { return }
            handlePendingNavigation(matchId: matchId)
        }
        .onAppear {
            if let matchId = navigationCoordinator.pendingMatchId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    handlePendingNavigation(matchId: matchId)
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainerView()
        }
    }

    // MARK: - Shared Logic

    private var splashScreen: some View {
        VStack {
            Spacer()
            Text("SHL")
                .font(.system(size: 72, weight: .heavy))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .zIndex(10)
        .transition(.move(edge: .bottom).animation(.easeInOut(duration: 300)))
        .task {
            let _ = try? await api.getCurrentStandings()
            let _ = try? await api.getLatestMatches()
            withAnimation { loggedIn = true }
            if !Settings.shared.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }

    private func loadTeams() async {
        do {
            teams = try await api.getTeams()
        } catch {
            print("Failed to load teams: \(error)")
        }
    }

    private func handlePendingNavigation(matchId: String) {
        let source = navigationCoordinator.navigationSource ?? "unknown"
        navigationCoordinator.clearPending()
        Task {
            guard let game = try? await api.getMatchDetail(id: matchId) else { return }
            await MainActor.run {
                selectedTab = .home
                openedGame = MatchView(game, referrer: source)
                isGameOpen = true
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "shltracker",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let action = components.host, action == "open-game",
              let gameId = components.queryItems?.first(where: { $0.name == "id" })?.value
        else { return }

        Task {
            guard let game = try? await api.getMatchDetail(id: gameId) else { return }
            selectedTab = .home
            openedGame = MatchView(game, referrer: "url-schema")
            isGameOpen = true
        }
    }
}
