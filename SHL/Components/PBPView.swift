//
//  PBPView.swift
//  SHL
//
//  Created by KibbeWater on 3/31/24.
//

import SwiftUI
import HockeyKit

struct PBPView: View {
    @Binding var events: [PBPEventProtocol]
    
    var body: some View {
        ForEach(events.indices.reversed(), id: \.self) { _ev in
            let ev = events[_ev]
            
            if let _goalkeeperEvent = ev as? GoalkeeperEvent {
                HStack {
                    if _goalkeeperEvent.eventTeam.place == .home {
                        VStack {
                            
                        }
                        .frame(maxHeight: .infinity)
                        .frame(width: 6)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: .infinity))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Goalkeeper \(_goalkeeperEvent.isEntering ? "In" : "Out") -")
                                .fontWeight(.semibold)
                            Text("\(_goalkeeperEvent.player.jerseyToday) \(_goalkeeperEvent.player.firstName) \(_goalkeeperEvent.player.familyName)")
                        }
                        .padding(.bottom)
                        Text("P\(_goalkeeperEvent.period) - \(_goalkeeperEvent.time)")
                    }
                    .padding(.horizontal, _goalkeeperEvent.eventTeam.place == .away ? 16 : 0)
                    Spacer()
                    if _goalkeeperEvent.eventTeam.place == .away {
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
            } else if let _penaltyEvent = ev as? PenaltyEvent {
                HStack {
                    if _penaltyEvent.eventTeam.place == .home {
                        VStack {
                            
                        }
                        .frame(maxHeight: .infinity)
                        .frame(width: 6)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: .infinity))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Penalty -")
                                .fontWeight(.semibold)
                            if let player = _penaltyEvent.player {
                                Text("\(player.jerseyToday) \(player.firstName) \(player.familyName)")
                            } else {
                                Text(_penaltyEvent.eventTeam.teamName)
                            }
                        }
                        Text("\(_penaltyEvent.offence) \(_penaltyEvent.variant.description != nil ? "- \(_penaltyEvent.variant.description!)" : "")")
                        .padding(.bottom)
                        Text("P\(_penaltyEvent.period) - \(_penaltyEvent.time)")
                    }
                    .padding(.horizontal, _penaltyEvent.eventTeam.place == .away ? 16 : 0)
                    Spacer()
                    if _penaltyEvent.eventTeam.place == .away {
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
                        HStack {
                            Text("Goal scored by\n\(_goalEvent.player.jerseyToday) \(_goalEvent.player.firstName) \(_goalEvent.player.familyName)")
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        HStack {
                            Text("P\(_goalEvent.period) - \(_goalEvent.time)")
                                .font(.footnote)
                            Spacer()
                        }
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
                HStack {
                    VStack {
                        HStack {
                            Text("Tactical Timeout")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        HStack {
                            Text("P\(_timeoutEvent.period) - \(_timeoutEvent.time)")
                                .font(.footnote)
                            Spacer()
                        }
                    }
                    Spacer()
                    let isHome = _timeoutEvent.eventTeam.teamId == _timeoutEvent.homeTeam.teamId
                    Image("Team/\(isHome ? _timeoutEvent.homeTeam.teamCode : _timeoutEvent.awayTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                }
                .padding([.trailing, .vertical], 8)
                .padding(.leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    PBPView(events: .constant([
        
    ]))
}
