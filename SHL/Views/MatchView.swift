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
                ForEach(pbpEvents.indices.reversed(), id: \.self) { _ev in
                    let ev = pbpEvents[_ev]
                    
                    if let _goalkeeperEvent = ev as? GoalkeeperEvent {
                        Text("Goalkeeper Event \(_goalkeeperEvent.gameId)")
                    } else if let _penaltyEvent = ev as? PenaltyEvent {
                        Text("Penalty Event \(_penaltyEvent.gameId)")
                    } else if let _shotEvent = ev as? ShotEvent {
                        HStack {
                            if _shotEvent.eventTeam.place == .home {
                                VStack {
                                    
                                }
                                .frame(maxHeight: .infinity)
                                .frame(width: 6)
                                .background(.red)
                                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                            }
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Shot -")
                                        .fontWeight(.semibold)
                                    Text("\(_shotEvent.player.jerseyToday) \(_shotEvent.player.firstName) \(_shotEvent.player.familyName)")
                                }
                                .padding(.bottom)
                                Text("P\(_shotEvent.period) - \(_shotEvent.time)")
                            }
                            .padding(.horizontal, _shotEvent.eventTeam.place == .away ? 16 : 0)
                            Spacer()
                            if _shotEvent.eventTeam.place == .away {
                                VStack {
                                    
                                }
                                .frame(maxHeight: .infinity)
                                .frame(width: 6)
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                            }
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                        HStack {
                            VStack {
                                Text("Goal scored by\n\(_goalEvent.player.jerseyToday) \(_goalEvent.player.firstName) \(_goalEvent.player.familyName)")
                            }
                            Spacer()
                            HStack {
                                let isHome = _goalEvent.eventTeam.teamId == _goalEvent.homeTeam.teamId
                                Text(String(isHome ? _goalEvent.homeGoals : _goalEvent.awayGoals))
                                    .font(.system(size: 48))
                                    .fontWidth(.compressed)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image("Team/\(isHome ? _goalEvent.homeTeam.teamCode : _goalEvent.awayTeam.teamCode)")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                            }
                            .frame(width: 96)
                        }
                        .padding([.trailing, .vertical], 8)
                        .padding(.leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if let _timeoutEvent = ev as? TimeoutEvent {
                        Text("Timeout Event \(_timeoutEvent.gameId)")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
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