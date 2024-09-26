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
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    private func loadTeamColors() {
        let _homeKey = "Team/\(game.homeTeam.code.uppercased())"
        let _awayKey = "Team/\(game.awayTeam.code.uppercased())"
        
        if let _homeColor = UIImage(named: _homeKey) {
            if let cache = ColorCache.shared.getColor(forKey: _homeKey) {
                withAnimation {
                    self.homeColor = Color(uiColor: cache)
                }
            } else {
                _homeColor.getColors(quality: .low) { clr in
                    if let _bg = clr?.background {
                        ColorCache.shared.cacheColor(_bg, forKey: _homeKey)
                        withAnimation {
                            self.homeColor = Color(uiColor: _bg)
                        }
                    }
                }
            }
        }
        
        if let _awayColor = UIImage(named: _awayKey) {
            if let cache = ColorCache.shared.getColor(forKey: _awayKey) {
                withAnimation {
                    self.awayColor = Color(uiColor: cache)
                }
            } else {
                _awayColor.getColors(quality: .low) { clr in
                    if let _bg = clr?.background {
                        ColorCache.shared.cacheColor(_bg, forKey: _awayKey)
                        withAnimation {
                            self.awayColor = Color(uiColor: _bg)
                        }
                    }
                }
            }
        }
    }
    
    init(game: Game) {
        self.game = game
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
                    Text(String(game.homeTeam.result))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(game.homeTeam.result > game.awayTeam.result ? .primary : .secondary)
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
                Text(game.shootout ? "Shootout" : game.overtime ? "Overtime" : game.played ? "Full-Time" : Calendar.current.isDate(game.date, inSameDayAs: Date()) ? game.formatTime() : game.formatDate())
                    .fontWeight(.medium)
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
                    Text(String(game.awayTeam.result))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(game.awayTeam.result > game.homeTeam.result ? .primary : .secondary)
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
            if let _venue = game.venue {
                Text(_venue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.leading)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            loadTeamColors()
        }
    }
}

#Preview {
    MatchOverview(game: Game.fakeData())
}
