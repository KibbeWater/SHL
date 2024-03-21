//
//  PrevMatch.swift
//  LHF
//
//  Created by KibbeWater on 3/21/24.
//

import SwiftUI
import HockeyKit

struct PrevMatch: View {
    var game: Game
    
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
                        .foregroundStyle(.primary)
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
                            colors: [.blue.opacity(0.5), .clear]),
                            startPoint: .leading, endPoint: .trailing
                        )
            )
            Spacer()
            VStack {
                Spacer()
                Text("Full-Time")
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
                        .foregroundStyle(.primary)
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
                                    colors: [.yellow.opacity(0.5), .clear]),
                                       startPoint: .trailing, endPoint: .leading
                        )
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
}

#Preview {
    PrevMatch(game: Game.fakeData())
}
