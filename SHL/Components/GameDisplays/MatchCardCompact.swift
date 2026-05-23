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
        if let liveGame {
            return liveGame.gameState == .ongoing || liveGame.gameState == .paused
        }
        return game.isLive()
    }

    private var isCancelled: Bool { game.isCancelled }

    private var isUpcoming: Bool {
        !game.concluded && !isLive
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
                    .font(.callout.weight(.bold))
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
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                TeamLogoView(teamCode: game.awayTeam.code, size: .custom(36))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(compactBackground)
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isLive ? .red.opacity(0.3) : .white.opacity(0.06), lineWidth: isLive ? 1 : 0.5)
        )
        .saturation(isCancelled ? 0 : 1)
        .opacity(isCancelled ? 0.65 : 1)
        .onAppear(perform: loadTeamColors)
        .sensoryFeedback(.impact(weight: .light), trigger: homeScore)
        .sensoryFeedback(.impact(weight: .light), trigger: awayScore)
    }

    @ViewBuilder
    private var centerContent: some View {
        if isCancelled {
            VStack(spacing: 2) {
                Text("—")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.tertiary)
                Text("Cancelled")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else if isLive {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse, options: .repeating)
                    Text("\(homeScore) – \(awayScore)")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.red)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                if let live = liveGame {
                    Text(live.gameState == .paused ? "Break" : "P\(live.period)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else if isUpcoming {
            VStack(spacing: 0) {
                Text(game.formatDate())
                    .font(.caption.weight(game.isToday ? .bold : .semibold))
                    .foregroundStyle(game.isToday ? .primary : .secondary)
                Text(game.formatTime())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        } else {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(homeScore)")
                        .font(.callout.weight(.bold))
                        .contentTransition(.numericText(value: Double(homeScore)))
                    Text("–")
                        .foregroundStyle(.tertiary)
                    Text("\(awayScore)")
                        .font(.callout.weight(.bold))
                        .contentTransition(.numericText(value: Double(awayScore)))
                }
                .foregroundStyle(.primary)
                .monospacedDigit()
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
        }
    }

    private var compactBackground: some View {
        ZStack {
            HStack(spacing: 0) {
                homeColor.opacity(0.18)
                Color.clear
                awayColor.opacity(0.18)
            }
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    private func loadTeamColors() {
        Task(priority: .low) {
            game.homeTeam.getTeamColor { color in
                withAnimation(.smooth(duration: 0.3)) { self.homeColor = color }
            }
            game.awayTeam.getTeamColor { color in
                withAnimation(.smooth(duration: 0.3)) { self.awayColor = color }
            }
        }
    }
}

#Preview {
    MatchCardCompact(game: Match.fakeData())
        .padding(.horizontal)
}
