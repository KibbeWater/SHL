//
//  LHFApp.swift
//  LHF
//
//  Created by user242911 on 12/30/23.
//

import SwiftUI
import HockeyKit

@main
struct LHFApp: App {
    var matchInfo: MatchInfo = MatchInfo()
    var leagueStandings: LeagueStandings = LeagueStandings()
    
    var body: some Scene {
        WindowGroup {
            Root()
                .environmentObject(matchInfo)
                .environmentObject(leagueStandings)
        }
    }
}
