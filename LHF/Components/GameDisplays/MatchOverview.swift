//
//  PrevMatch.swift
//  LHF
//
//  Created by KibbeWater on 3/21/24.
//

import SwiftUI
import HockeyKit

struct MatchOverview: View {
    var game: Game
    var liveGame: GameOverview?
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
    }
    
    func FormatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
    
    private func loadTeamColors() {
        let _homeColor = Color(UIImage(named: "Team/\(game.homeTeam.code)")?.getColors(quality: .low)?.background ?? UIColor.black)
        let _awayColor = Color(UIImage(named: "Team/\(game.awayTeam.code)")?.getColors(quality: .low)?.background ?? UIColor.black)
        
        withAnimation {
            self.homeColor = _homeColor
            self.awayColor = _awayColor
        }
    }
    
    init(game: Game, liveGame: GameOverview? = nil) {
        self.game = game
        if game.id == liveGame?.gameUuid {
            self.liveGame = liveGame
        }
    }
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    VStack {
                        Spacer()
                        Image("Team/\(game.homeTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                        Spacer()
                    }
                    Spacer()
                    Text(String(liveGame?.homeGoals ?? game.homeTeam.result))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(liveGame?.homeGoals ?? game.homeTeam.result > liveGame?.awayGoals ?? game.awayTeam.result ? .primary : .secondary)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(game.homeTeam.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 48)
                }
                .frame(width: 96)
            }
            .padding(.leading)
            .padding(.vertical, 8)
            .background(LinearGradient(gradient:
                                        Gradient(
                                            colors: [homeColor.opacity(0.5), .clear]),
                                       startPoint: .leading, endPoint: .trailing
                                      )
            )
            Spacer()
            VStack {
                Spacer()
                if let _liveGame = liveGame {
                    if _liveGame.state == .starting {
                        Text("Starting")
                    } else if _liveGame.state == .ongoing {
                        Text("P\(_liveGame.time.period): \(_liveGame.time.periodTime)")
                    } else if _liveGame.state == .onbreak {
                        Text("P\(_liveGame.time.period): Pause")
                    } else if _liveGame.state == .overtime {
                        Text("OT: \(_liveGame.time.periodTime)")
                    } else if _liveGame.state == .ended {
                        Text("Ended")
                    }
                } else {
                    Text(game.shootout ? "Shootout" : game.overtime ? "Overtime" : game.played ? "Full-Time" : Calendar.current.isDate(game.date, inSameDayAs: Date()) ? FormatTime(game.date) : FormatDate(game.date))
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                Text(game.seriesCode.rawValue)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            Spacer()
            VStack {
                HStack {
                    Text(String(liveGame?.awayGoals ?? game.awayTeam.result))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(liveGame?.awayGoals ?? game.awayTeam.result > liveGame?.homeGoals ?? game.homeTeam.result ? .primary : .secondary)
                    Spacer()
                    VStack {
                        Spacer()
                        Image("Team/\(game.awayTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                        Spacer()
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Text(game.awayTeam.name)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 48)
                }
                .frame(width: 96)
            }
            .padding(.trailing)
            .padding(.vertical, 8)
            .background(LinearGradient(gradient:
                                        Gradient(
                                            colors: [awayColor.opacity(0.5), .clear]),
                                       startPoint: .trailing, endPoint: .leading
                                      )
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 102)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .overlay(alignment: .topLeading) {
            Text(game.venue)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading)
                .padding(.top, 8)
            
        }
        .onAppear {
            loadTeamColors()
        }
    }
}

#Preview {
    MatchOverview(game: Game.fakeData())
}
