//
//  Root_iOS.swift
//  SHL
//
//  iPhone-specific root layout — standard TabView with 3 tabs
//

import SHLCore
import SHLNetwork
import SwiftUI

struct Root_iOS: View {
    @State private var loggedIn = false
    @State private var showOnboarding = false

    private let api = SHLAPIClient.shared

    @State private var openedGame: MatchView?
    @State private var isGameOpen = false

    @State private var selectedTab: RootTabs = .home

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
            }

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
        // iPhone doesn't use team tabs, but preload for other features
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
