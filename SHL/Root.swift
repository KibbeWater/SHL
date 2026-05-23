//
//  Root.swift
//  LHF
//
//  Created by user242911 on 3/23/24.
//

import SwiftUI

enum RootTabs: Equatable, Hashable, Identifiable {
    case home
    case calendar
    case standings
    case settings
    case search
    case team(Team)

    var id: String {
        switch self {
        case .home: return "home"
        case .calendar: return "calendar"
        case .standings: return "standings"
        case .settings: return "settings"
        case .search: return "search"
        case .team(let team): return "team_\(team.id)"
        }
    }
}

struct Root: View {
    @State private var loggedIn = false
    @State private var showOnboarding = false
    @State private var splashIconScale: CGFloat = 0.6
    @State private var splashIconRotation: Double = -8
    @State private var splashOpacity: Double = 0

    private let api = SHLAPIClient.shared

    @State private var openedGame: MatchView?
    @State private var isGameOpen = false

    @State private var selectedTab: RootTabs = .home

    @State private var teams: [Team] = []

    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @StateObject private var adminPairingCoordinator = AdminPairingCoordinator.shared
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var scheduleViewModel = MatchListViewModel()

    @AppStorage("tabViewCustomization") private var tabCustomization: TabViewCustomization = .init()

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                TabView(selection: $selectedTab) {
                    Tab("Home", systemImage: "house", value: RootTabs.home) {
                        NavigationStack {
                            if isIPad {
                                iPadHomeContent(
                                    viewModel: homeViewModel,
                                    onSelectMatch: { match in
                                        openedGame = MatchView(match, referrer: "home")
                                        isGameOpen = true
                                    }
                                )
                                .navigationDestination(isPresented: $isGameOpen) {
                                    openedGame
                                }
                            } else {
                                HomeView()
                                    .navigationDestination(isPresented: $isGameOpen) {
                                        openedGame
                                    }
                            }
                        }
                    }
                    .customizationBehavior(.disabled, for: .sidebar, .tabBar)

                    Tab("Schedule", systemImage: "calendar", value: RootTabs.calendar) {
                        NavigationStack {
                            if isIPad {
                                iPadScheduleContent(
                                    viewModel: scheduleViewModel,
                                    onSelectMatch: { match in
                                        openedGame = MatchView(match, referrer: "schedule")
                                        isGameOpen = true
                                    }
                                )
                                .navigationTitle("Schedule")
                            } else {
                                MatchListView()
                            }
                        }
                    }
                    .customizationBehavior(.disabled, for: .sidebar, .tabBar)

                    Tab("Settings", systemImage: "gearshape", value: RootTabs.settings) {
                        NavigationStack {
                            SettingsView()
                        }
                    }
                    .customizationBehavior(.disabled, for: .sidebar, .tabBar)

                    #if DEBUG
                    if #available(iOS 26.0, *) {
                        Tab(value: RootTabs.search, role: .search) {
                            SearchView()
                        }
                    }
                    #endif

                    if isIPad {
                        Tab("Standings", systemImage: "list.number", value: RootTabs.standings) {
                            NavigationStack {
                                iPadStandingsContent(
                                    viewModel: homeViewModel,
                                    onSelectTeam: { _ in }
                                )
                                .navigationTitle("Standings")
                            }
                        }
                        .customizationID("shl.standings")
                        .defaultVisibility(.hidden, for: .tabBar)

                        TabSection("Teams") {
                            ForEach(teams, id: \.id) { team in
                                Tab(value: RootTabs.team(team)) {
                                    NavigationStack {
                                        TeamView(team: team)
                                    }
                                } label: {
                                    HStack {
                                        if let img = svgToImage(named: "Team/\(team.code.uppercased())", width: 22) {
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 22, height: 22)
                                        }
                                        Text(team.name)
                                    }
                                }
                                .customizationID("shl.team.\(team.id)")
                                .defaultVisibility(.hidden, for: .tabBar)
                            }
                        }
                        .customizationID("shl.teams")
                        .defaultVisibility(.hidden, for: .tabBar)
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
                .tabViewCustomization($tabCustomization)
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        HomeView()
                            .navigationDestination(isPresented: $isGameOpen) {
                                openedGame
                            }
                    }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    NavigationStack {
                        MatchListView()
                    }
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            }
            
            if !loggedIn {
                splashView
                    .zIndex(10)
                    .transition(.opacity.combined(with: .scale(scale: 1.08, anchor: .center)))
                    .task {
                        // Animate entrance
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                            splashIconScale = 1
                            splashIconRotation = 0
                            splashOpacity = 1
                        }

                        do {
                            let _ = try? await api.getCurrentStandings()
                        } catch let _err {
                            print(_err)
                        }

                        do {
                            let _ = try await api.getLatestMatches()
                        } catch let _err {
                            print(_err)
                        }

                        // Give the splash a beat to breathe before dismissing
                        try? await Task.sleep(nanoseconds: 250_000_000)

                        withAnimation(.smooth(duration: 0.45)) {
                            loggedIn = true
                        }

                        // Check if onboarding needed (after splash)
                        if !Settings.shared.hasCompletedOnboarding {
                            showOnboarding = true
                        }
                    }
            }
        }
        .tint(.accentColor)
        .sensoryFeedback(.success, trigger: loggedIn) { _, new in new }
        .task {
            do {
                // Get basic teams, then fetch details for each
                let basicTeams = try await api.getTeams()
                teams = try await api.getTeams()
            } catch let _err {
                print(_err)
            }
        }
        .onAppear {
            Task {
                await ReminderContext.refreshActiveReminders()
            }
        }
        .onOpenURL { incomingURL in
            print("App was opened via URL: \(incomingURL)")
            handleIncomingURL(incomingURL)
        }
        .onChange(of: navigationCoordinator.pendingMatchId) { oldValue, newValue in
            guard let matchId = newValue else { return }
            handlePendingNavigation(matchId: matchId)
        }
        .onAppear {
            // Handle cold start navigation (app was terminated)
            if let matchId = navigationCoordinator.pendingMatchId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    handlePendingNavigation(matchId: matchId)
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainerView()
        }
        .sheet(isPresented: $adminPairingCoordinator.isPresented) {
            AdminPairingSheet()
                .environmentObject(adminPairingCoordinator)
        }
    }

    // MARK: - Splash

    private var splashView: some View {
        ZStack {
            // Subtle radial backdrop so the icon feels lit from behind
            RadialGradient(
                colors: [Color.accentColor.opacity(0.22), Color(uiColor: .systemBackground)],
                center: .center,
                startRadius: 8,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "hockey.puck.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.hierarchical)
                    .rotationEffect(.degrees(splashIconRotation))
                    .scaleEffect(splashIconScale)
                    .shadow(color: .black.opacity(0.15), radius: 18, y: 8)

                VStack(spacing: 4) {
                    Text("SHL")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .kerning(2)
                    Text("Tracker")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(3)
                }
                .opacity(splashOpacity)

                Spacer()

                ProgressView()
                    .controlSize(.small)
                    .tint(.secondary)
                    .opacity(splashOpacity * 0.6)
                    .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private func handlePendingNavigation(matchId: String) {
        let source = navigationCoordinator.navigationSource ?? "unknown"
        navigationCoordinator.clearPending()

        Task {
            guard let game = try? await api.getMatchDetail(id: matchId) else {
                print("Unable to find game for navigation: \(matchId)")
                return
            }

            await MainActor.run {
                selectedTab = .home
                openedGame = MatchView(game, referrer: source)
                isGameOpen = true
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "shltracker" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }

        switch components.host {
        case "open-game":
            handleOpenGame(components: components)
        case "link":
            handleAdminLink(components: components)
        default:
            print("Unknown URL, we can't handle this one!")
        }
    }

    private func handleOpenGame(components: URLComponents) {
        guard let gameId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return
        }

        Task { // shltracker://open-game?id=0BC4115B-A6F8-49E4-A9A4-57C0120ECDA9
            guard let game = try? await api.getMatchDetail(id: gameId) else {
                print("Unable to find game")
                return
            }

            selectedTab = .home
            openedGame = MatchView(game, referrer: "url-schema")
            isGameOpen = true
        }
    }

    private func handleAdminLink(components: URLComponents) {
        guard let raw = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return
        }
        AdminPairingCoordinator.shared.start(rawCode: raw)
    }
}

#Preview {
    Root()
}
