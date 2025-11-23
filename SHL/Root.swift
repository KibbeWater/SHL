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
    case settings
    case search
    case team(Team)

    var id: String {
        switch self {
        case .home: return "home"
        case .calendar: return "calendar"
        case .settings: return "settings"
        case .search: return "search"
        case .team(let team): return "team_\(team.id)"
        }
    }
}

struct Root: View {
    @State private var loggedIn = false

    private let api = SHLAPIClient.shared

    @State private var openedGame: MatchView?
    @State private var isGameOpen = false

    @State private var selectedTab: RootTabs = .home

    @State private var teams: [Team] = []
    
    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
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
                    
                    if #available(iOS 26.0, *) {
                        Tab(value: RootTabs.search, role: .search) {
                            SearchView()
                        }
                    }
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
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
                }
                .tabViewStyle(.sidebarAdaptable)
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
                VStack {
                    Spacer()
                    
                    Text("SHL")
                        .font(.system(size: 72, weight: .heavy))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemBackground))
                .zIndex(10)
                .transition(
                    .move(edge: .bottom)
                        .animation(.easeInOut(duration: 300))
                )
                .task {
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

                    withAnimation {
                        loggedIn = true
                    }
                }
            }
        }
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
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "shltracker" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }
        
        guard let action = components.host, action == "open-game" else {
            print("Unknown URL, we can't handle this one!")
            return
        }
        
        guard let gameId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return
        }
        
        // TODO: Find Games based on ID and display it
        Task { // shltracker:open-game?id=0BC4115B-A6F8-49E4-A9A4-57C0120ECDA9
            guard let game = try? await api.getMatchDetail(id: gameId) else {
                print("Unable to find game")
                return
            }
            
            selectedTab = .home
            openedGame = MatchView(game, referrer: "url-schema")
            isGameOpen = true
        }
    }
}

#Preview {
    Root()
}
