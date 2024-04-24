//
//  LHF_DemoApp.swift
//  LHF Demo
//
//  Created by KibbeWater on 3/25/24.
//

import SwiftUI
import HockeyKit

@main
struct LHF_DemoApp: App {
    var matchInfo = MatchInfo()
    var leagueStandigs = LeagueStandings()
    
    var body: some Scene {
        WindowGroup {
            Root()
                .environmentObject(matchInfo)
                .environmentObject(leagueStandigs)
        }
    }
}
