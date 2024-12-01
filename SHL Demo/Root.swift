//
//  Root.swift
//  SHL Demo
//
//  Created by Linus Rönnbäck Larsson on 2024-04-24.
//

import SwiftUI
import HockeyKit

struct Root: View {
    @EnvironmentObject var api: HockeyAPI
    
    @State private var loggedIn = false
    
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
                        if let series = try await api.series.getCurrentSeries() {
                            let _ = try await api.standings.getStandings(series: series)
                        }
                    } catch let _err {
                        print(_err)
                    }
                    
                    do {
                        let _ = try await api.match.getLatest()
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
        .environmentObject(HockeyAPI())
}
