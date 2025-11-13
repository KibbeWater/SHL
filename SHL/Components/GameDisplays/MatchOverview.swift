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
    var liveGame: LiveMatch?

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

    init(game: Match, liveGame: LiveMatch? = nil) {
        self.game = game
        if game.externalUUID == liveGame?.externalId {
            self.liveGame = liveGame
        }
    }
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    VStack {
                        Spacer()
                        TeamLogoView(teamCode: game.homeTeam.code, size: .medium)
                        Spacer()
                    }
                    Spacer()
                    Text(String(liveGame?.homeScore ?? game.homeScore))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(liveGame?.homeScore ?? game.homeScore > liveGame?.awayScore ?? game.awayScore ? .primary : .secondary)
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
                    switch _liveGame.gameState {
                    case .scheduled:
                        Text("Starting")
                    case .ongoing:
                        Text("P\(_liveGame.period): \(_liveGame.periodTime)")
                    case .paused:
                        Text("P\(_liveGame.period): Pause")
                    case .played:
                        Text("Ended")
                    }
                } else {
                    Text((game.shootout ?? false) ? "Shootout" : (game.overtime ?? false) ? "Overtime" : game.played ? "Full-Time" : Calendar.current.isDate(game.date, inSameDayAs: Date()) ? game.formatTime() : game.formatDate())
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
                    Text(String(liveGame?.awayScore ?? game.awayScore))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(liveGame?.awayScore ?? game.awayScore > liveGame?.homeScore ?? game.homeScore ? .primary : .secondary)
                    Spacer()
                    VStack {
                        Spacer()
                        TeamLogoView(teamCode: game.awayTeam.code, size: .medium)
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
