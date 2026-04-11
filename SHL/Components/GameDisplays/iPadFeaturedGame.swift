//
//  iPadFeaturedGame.swift
//  SHL
//
//  Featured game card designed for iPad content column
//

import SwiftUI

struct iPadFeaturedGame: View {
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
        VStack(spacing: 0) {
            // Status bar
            statusBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Main matchup
            HStack(spacing: 0) {
                // Home team
                teamColumn(
                    code: game.homeTeam.code,
                    name: game.homeTeam.name,
                    isLeading: homeScore > awayScore
                )

                // Center: score or VS
                centerContent
                    .frame(minWidth: 100)

                // Away team
                teamColumn(
                    code: game.awayTeam.code,
                    name: game.awayTeam.name,
                    isLeading: awayScore > homeScore
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Venue bar
            if let venue = game.venue {
                Divider()
                    .opacity(0.3)
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(venue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    if let resultText = gameResultText {
                        Text(resultText)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.5))
                            .textCase(.uppercase)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .saturation(isCancelled ? 0 : 1)
        .opacity(isCancelled ? 0.7 : 1)
        .onAppear(perform: loadTeamColors)
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        HStack {
            if isLive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(.red.opacity(0.4))
                                .frame(width: 16, height: 16)
                        )
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)

                    if let live = liveGame {
                        Text("\u{00B7}")
                            .foregroundStyle(.white.opacity(0.5))
                        Text(periodText(for: live))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            } else if isCancelled {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("CANCELLED")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else if isUpcoming {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(game.formatDate())
                        .font(.caption)
                        .fontWeight(game.isToday ? .bold : .medium)
                        .foregroundStyle(.white)
                    Text("\u{00B7}")
                        .foregroundStyle(.white.opacity(0.5))
                    Text(game.formatTime())
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Final")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            Spacer()
        }
    }

    // MARK: - Team Column

    private func teamColumn(code: String, name: String, isLeading: Bool) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(teamCode: code, size: .custom(64))
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

            Text(code)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Center Content

    @ViewBuilder
    private var centerContent: some View {
        if isCancelled {
            Text("\u{2014}")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        } else if isUpcoming {
            Text("VS")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        } else {
            Text("\(homeScore) - \(awayScore)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Helpers

    private func periodText(for live: LiveMatch) -> String {
        switch live.gameState {
        case .ongoing:
            return "P\(live.period) \(live.periodTime)"
        case .paused:
            return "P\(live.period) Break"
        case .scheduled, .played, .cancelled:
            return ""
        }
    }

    private var gameResultText: String? {
        guard !isUpcoming && !isLive && !isCancelled else { return nil }
        if game.shootout ?? false { return "Shootout" }
        if game.overtime ?? false { return "Overtime" }
        return nil
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: homeColor, location: 0),
                    .init(color: homeColor.opacity(0.7), location: 0.35),
                    .init(color: awayColor.opacity(0.7), location: 0.65),
                    .init(color: awayColor, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            // Darken slightly for text readability
            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.05), .black.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func loadTeamColors() {
        Task(priority: .low) {
            game.homeTeam.getTeamColor { color in
                withAnimation(.easeInOut(duration: 0.3)) { self.homeColor = color }
            }
            game.awayTeam.getTeamColor { color in
                withAnimation(.easeInOut(duration: 0.3)) { self.awayColor = color }
            }
        }
    }
}

#Preview {
    iPadFeaturedGame(game: Match.fakeData())
        .padding()
}
