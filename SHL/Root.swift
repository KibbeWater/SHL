//
//  Root.swift
//  LHF
//
//  Created by user242911 on 3/23/24.
//

import SwiftUI
import HockeyKit

enum RootTabs: Equatable, Hashable, Identifiable {
    case home
    case calendar
    case settings
    case team(SiteTeam)
    
    var id: String {
        switch self {
        case .home: return "home"
        case .calendar: return "calendar"
        case .settings: return "settings"
        case .team(let team): return "team_\(team.id)"
        }
    }
}

struct Root: View {
    @State private var loggedIn = false
    
    @Environment(\.hockeyAPI) var hockeyApi: HockeyAPI
    
    @State private var openedGame: MatchView?
    @State private var isGameOpen = false
    
    @State private var selectedTab: RootTabs = .home
    
    @State private var teams: [SiteTeam] = []
    
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
                        SettingsView()
                    }
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        TabSection("Teams") {
                            ForEach(teams, id: \.id) { team in
                                Tab(value: RootTabs.team(team)) {
                                    TeamView(team: team)
                                } label: {
                                    HStack {
                                        svgToImage(named: "Team/\(team.names.code.uppercased())", width: 28)!
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                        Text(team.names.longSite ?? team.name)
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
                        if let series = try await hockeyApi.series.getCurrentSeries() {
                            let _ = try await hockeyApi.standings.getStandings(series: series)
                        }
                    } catch let _err {
                        print(_err)
                    }
                    
                    do {
                        let _ = try await hockeyApi.match.getLatest()
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
                teams = try await hockeyApi.team.getTeams()
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
        
        guard let matchId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            print("Hello")
            return
        }
        
        // TODO: Find Games based on ID and display it
        /* Task {
            guard let game = try? await hockeyApi.match.getMatchExtra(matchId) else {
                print("Unable to find game")
                return
            }
            selectedTab = .home
            openedGame = MatchView(match: Game(game))
            isGameOpen = true
        } */
    }
}

#Preview {
    Root()
        .environmentObject(HockeyAPI())
}
