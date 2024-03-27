//
//  DebugView.swift
//  LHF
//
//  Created by user242911 on 1/3/24.
//

import SwiftUI
import HockeyKit

struct DebugView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    var body: some View {
        VStack {
            ForEach(matchInfo.latestMatches.filter(IsLive), id: \.id) { match in
                Button("\(match.homeTeam.name) v. \(match.awayTeam.name)") {
                    Task {
                        do {
                            if let overview = try await matchInfo.getMatch(match.id) {
                                try ActivityUpdater.shared.start(match: overview)
                            }
                        } catch let err {
                            print("Error fetching match")
                            print(err)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    func IsLive(_ game: Game) -> Bool {
        return !game.played && game.date < Date.now
    }
}

#Preview {
    DebugView()
        .environmentObject(MatchInfo())
}
