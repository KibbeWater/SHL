//
//  Root.swift
//  LHF
//
//  Created by user242911 on 3/23/24.
//

import SwiftUI
import HockeyKit

struct Root: View {
    var body: some View {
        NavigationStack {
            ContentView()
        }
    }
}

#Preview {
    Root()
        .environmentObject(MatchInfo())
        .environmentObject(LeagueStandings())
}
