//
//  PrevMatch.swift
//  LHF
//
//  Created by KibbeWater on 3/21/24.
//

import SwiftUI
import HockeyKit

struct MatchOverview: View {
    var game: Match
    var liveGame: GameData.GameOverview?

    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear

    private func loadTeamColors() {
        game.awayTeam.getTeamColor { clr in
            withAnimation {
                self.awayColor = clr
            }
        }

        game.homeTeam.getTeamColor { clr in
            withAnimation {
                self.homeColor = clr
            }
        }
    }

    init(game: Match, liveGame: GameData.GameOverview? = nil) {
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
                        Image("Team/\(game.homeTeam.code.uppercased())")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                        Spacer()
                    }
                    Spacer()
                    Text(String(liveGame?.homeGoals ?? game.homeScore))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(liveGame?.homeGoals ?? game.homeScore > liveGame?.awayGoals ?? game.awayScore ? .primary : .secondary)
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
                    Text(game.shootout ? "Shootout" : game.overtime ? "Overtime" : game.played ? "Full-Time" : Calendar.current.isDate(game.date, inSameDayAs: Date()) ? game.formatTime() : game.formatDate())
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                // Text(game.seriesCode.rawValue)
                Text("SHL")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            Spacer()
            VStack {
                HStack {
                    Text(String(liveGame?.awayGoals ?? game.awayScore))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(liveGame?.awayGoals ?? game.awayScore > liveGame?.homeGoals ?? game.homeScore ? .primary : .secondary)
                    Spacer()
                    VStack {
                        Spacer()
                        Image("Team/\(game.awayTeam.code.uppercased())")
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
        .overlay(alignment: .topLeading) {
            if let venue = game.venue {
                Text(venue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.leading)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            if awayColor == .black || homeColor == .black {
                Task(priority: .low) {
                    loadTeamColors()
                }
            }
        }
    }
}

#Preview {
    MatchOverview(game: Match.fakeData())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
}
