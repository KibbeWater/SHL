//
//  Root.swift
//  LHF
//
//  Created by user242911 on 3/23/24.
//

import SwiftUI
import HockeyKit

struct Root: View {
    @State private var loggedIn = false
    
    @EnvironmentObject var matchInfo: MatchInfo
    @EnvironmentObject var leagueStandings: LeagueStandings
    
    @State private var openedGame: MatchView?
    @State private var isGameOpen = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                ContentView()
                    .navigationDestination(isPresented: $isGameOpen) {
                        openedGame
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
                        let _ = try await leagueStandings.fetchLeague(league: .SHL, skipCache: true)
                    } catch let _err {
                        print(_err)
                    }
                    
                    do {
                        try await matchInfo.getLatest()
                    } catch let _err {
                        print(_err)
                    }
                    
                    withAnimation {
                        loggedIn = true
                    }
                }
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
        
        Task {
            guard let game = try? await matchInfo.getMatchExtra(matchId) else {
                print("Unable to find game")
                return
            }
            openedGame = MatchView(match: Game(game))
            isGameOpen = true
        }
    }
}

#Preview {
    Root()
        .environmentObject(MatchInfo())
        .environmentObject(LeagueStandings())
}
