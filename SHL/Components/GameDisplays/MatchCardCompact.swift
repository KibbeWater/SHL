//
//  MatchCardCompact.swift
//  SHL
//
//  Compact match card for calendar lists and tight spaces
//

import SwiftUI

struct MatchCardCompact: View {
    let game: Match
    let liveGame: LiveMatch?

    @State private var homeColor: Color = .gray
    @State private var awayColor: Color = .gray

    private var homeScore: Int {
        liveGame?.homeScore ?? game.homeScore
    }

    private var awayScore: Int {
        liveGame?.awayScore ?? game.awayScore
    }

    private var isLive: Bool {
        liveGame?.gameState == .ongoing || liveGame?.gameState == .paused || game.isLive()
    }

    private var isUpcoming: Bool {
        !game.played && !isLive
    }

    init(game: Match, liveGame: LiveMatch? = nil) {
        self.game = game
        self.liveGame = game.externalUUID == liveGame?.externalId ? liveGame : nil
    }

    var body: some View {
        HStack(spacing: 0) {
            // Home team
            HStack(spacing: 8) {
                TeamLogoView(teamCode: game.homeTeam.code, size: .custom(36))
                Text(game.homeTeam.code)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Center: Score or Time
            centerContent
                .frame(width: 70)

            // Away team
            HStack(spacing: 8) {
                Text(game.awayTeam.code)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                TeamLogoView(teamCode: game.awayTeam.code, size: .custom(36))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(compactBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear(perform: loadTeamColors)
    }

    @ViewBuilder
    private var centerContent: some View {
        if isLive {
            HStack(spacing: 4) {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                Text("\(homeScore) - \(awayScore)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
            }
        } else if isUpcoming {
            VStack(spacing: 0) {
                Text(game.formatDate())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(game.formatTime())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        } else {
            HStack(spacing: 4) {
                Text("\(homeScore)")
                    .font(.callout)
                    .fontWeight(.bold)
                Text("-")
                    .foregroundStyle(.tertiary)
                Text("\(awayScore)")
                    .font(.callout)
                    .fontWeight(.bold)
                if game.overtime ?? false {
                    Text("OT")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if game.shootout ?? false {
                    Text("SO")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    private var compactBackground: some View {
        ZStack {
            HStack(spacing: 0) {
                homeColor.opacity(0.15)
                Color.clear
                awayColor.opacity(0.15)
            }
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    private func loadTeamColors() {
        Task(priority: .low) {
            game.homeTeam.getTeamColor { color in
                withAnimation { self.homeColor = color }
            }
            game.awayTeam.getTeamColor { color in
                withAnimation { self.awayColor = color }
            }
        }
    }
}

#Preview {
    MatchCardCompact(game: Match.fakeData())
        .padding(.horizontal)
}
