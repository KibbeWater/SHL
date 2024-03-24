//
//  PrevMatchView.swift
//  LHF
//
//  Created by user242911 on 3/24/24.
//

import SwiftUI
import HockeyKit

struct MatchView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    let match: Game
    
    @State private var pbpEvents: [PBPEventProtocol] = []
    
    var body: some View {
        VStack {
            Text(match.id)
                .padding(.bottom)
            
            ScrollView {
                ForEach(pbpEvents.indices, id: \.self) { _ev in
                    let ev = pbpEvents[_ev]
                    
                    if let _goalkeeperEvent = ev as? GoalkeeperEvent {
                        Text("Goalkeeper Event \(_goalkeeperEvent.gameId)")
                    } else if let _penaltyEvent = ev as? PenaltyEvent {
                        Text("Penalty Event \(_penaltyEvent.gameId)")
                    } else if let _shotEvent = ev as? ShotEvent {
                        Text("Shot Event \(_shotEvent.gameId)")
                    } else if let _periodEvent = ev as? PeriodEvent {
                        if _periodEvent.finished {
                            Text("Period \(_periodEvent.period) ended")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.vertical)
                        } else if _periodEvent.started {
                            Text("Period \(_periodEvent.period) started")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.vertical)
                        }
                    } else if let _goalEvent = ev as? GoalEvent {
                        Text("Goal Event \(_goalEvent.gameId)")
                    }
                }
            }
        }
        .task {
            do {
                if let events = try await matchInfo.getMatchPBP(match.id) {
                    pbpEvents = events
                }
            } catch {
                print("Failed to get play-by-play events")
            }
        }
    }
}

#Preview {
    MatchView(match: Game.fakeData())
        .environmentObject(MatchInfo())
}
