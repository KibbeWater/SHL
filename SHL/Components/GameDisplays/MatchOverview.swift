//
//  MatchOverview.swift
//  SHL
//
//  Match overview card with team colors and score display
//

import SwiftUI

struct MatchOverview: View {
    var game: Match
    var liveGame: LiveMatch?

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

    private var showStatusBar: Bool {
        isLive || isUpcoming
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status bar (only for live/upcoming)
            if showStatusBar {
                statusBar
            }

            // Main content
            HStack(spacing: 0) {
                // Home team
                teamView(
                    code: game.homeTeam.code,
                    score: homeScore,
                    isHome: true,
                    isWinning: homeScore > awayScore
                )

                // Center divider with VS or score indicator
                centerDivider

                // Away team
                teamView(
                    code: game.awayTeam.code,
                    score: awayScore,
                    isHome: false,
                    isWinning: awayScore > homeScore
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            if let resultText = gameResultText, !isLive && !isUpcoming {
                Text(resultText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .onAppear(perform: loadTeamColors)
    }

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
                                .fill(.red.opacity(0.5))
                                .frame(width: 16, height: 16)
                        )
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.red)

                    if let live = liveGame {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(periodText(for: live))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if isUpcoming {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(game.formatDate())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(game.formatTime())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let venue = game.venue {
                Text(venue)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    @ViewBuilder
    private func teamView(code: String, score: Int, isHome: Bool, isWinning: Bool) -> some View {
        HStack(spacing: 10) {
            if !isHome {
                Spacer(minLength: 0)
            }

            if isHome {
                TeamLogoView(teamCode: code, size: .custom(44))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                Text(code)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            } else {
                Text(code)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                TeamLogoView(teamCode: code, size: .custom(44))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }

            if isHome {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var centerDivider: some View {
        if isUpcoming {
            Text("VS")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 50)
        } else {
            Text("\(homeScore) - \(awayScore)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .frame(width: 90)
        }
    }

    private func periodText(for live: LiveMatch) -> String {
        switch live.gameState {
        case .ongoing:
            return "P\(live.period) \(live.periodTime)"
        case .paused:
            return "P\(live.period) Intermission"
        default:
            return ""
        }
    }

    private var gameResultText: String? {
        if game.shootout ?? false {
            return "Shootout"
        } else if game.overtime ?? false {
            return "Overtime"
        }
        return nil
    }

    private var cardBackground: some View {
        ZStack {
            // Base gradient with team colors
            LinearGradient(
                stops: [
                    .init(color: homeColor.opacity(0.35), location: 0),
                    .init(color: homeColor.opacity(0.1), location: 0.3),
                    .init(color: .clear, location: 0.5),
                    .init(color: awayColor.opacity(0.1), location: 0.7),
                    .init(color: awayColor.opacity(0.35), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            // Subtle top highlight
            LinearGradient(
                colors: [.white.opacity(0.1), .clear],
                startPoint: .top,
                endPoint: .center
            )

            // Material overlay for depth
            Rectangle()
                .fill(.ultraThinMaterial)
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

#Preview("Played") {
    MatchOverview(game: Match.fakeData())
        .padding(.horizontal)
}

#Preview("Upcoming") {
    MatchOverview(game: Match(
        id: "preview-upcoming",
        date: Date().addingTimeInterval(86400),
        venue: "Be-Ge Hockey Center",
        homeTeam: TeamBasic(id: "team-1", name: "IK Oskarshamn", code: "IKO"),
        awayTeam: TeamBasic(id: "team-2", name: "Frölunda HC", code: "FHC"),
        homeScore: 0,
        awayScore: 0,
        state: .scheduled,
        overtime: nil,
        shootout: nil,
        externalUUID: "preview"
    ))
    .padding(.horizontal)
}

#Preview("Live") {
    MatchOverview(
        game: Match(
            id: "preview-live",
            date: Date(),
            venue: "Be-Ge Hockey Center",
            homeTeam: TeamBasic(id: "team-1", name: "IK Oskarshamn", code: "IKO"),
            awayTeam: TeamBasic(id: "team-2", name: "Frölunda HC", code: "FHC"),
            homeScore: 2,
            awayScore: 1,
            state: .ongoing,
            overtime: nil,
            shootout: nil,
            externalUUID: "live-preview"
        ),
        liveGame: LiveMatch(
            id: "live-1",
            externalId: "live-preview",
            homeTeam: Team(id: "team-1", name: "IK Oskarshamn", code: "IKO", city: nil, founded: nil, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true),
            awayTeam: Team(id: "team-2", name: "Frölunda HC", code: "FHC", city: nil, founded: nil, venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true),
            homeScore: 2,
            awayScore: 1,
            period: 2,
            periodTime: "12:34",
            periodEnd: Date().addingTimeInterval(600),
            gameState: .ongoing
        )
    )
    .padding(.horizontal)
}
