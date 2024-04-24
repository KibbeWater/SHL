//
//  Root.swift
//  SHL Demo
//
//  Created by Linus Rönnbäck Larsson on 2024-04-24.
//

import SwiftUI
import HockeyKit

struct Root: View {
    @State private var loggedIn = false
    
    @EnvironmentObject var matchInfo: MatchInfo
    @EnvironmentObject var leagueStandings: LeagueStandings
    
    var body: some View {
        ZStack {
            NavigationStack {
                ContentView()
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
    }
}

#Preview {
    Root()
}
