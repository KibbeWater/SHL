//
//  ContentView.swift
//  LHF
//
//  Created by KibbeWater on 12/30/23.
//

import ActivityKit
import PostHog
import SwiftUI

public struct LiveGame {
    public var id: String
    public var homeTeam: LiveTeam
    public var awayTeam: LiveTeam
    public var time: LiveTime

    init(game: Match) {
        self.id = game.id
        self.homeTeam = LiveTeam(name: game.homeTeam.name, code: game.homeTeam.code, score: game.homeScore)
        self.awayTeam = LiveTeam(name: game.awayTeam.name, code: game.awayTeam.code, score: game.awayScore)
        self.time = LiveTime(period: 0, time: "00:00")
    }

    public struct LiveTeam {
        public var name: String
        public var code: String
        public var score: Int
    }

    public struct LiveTime {
        public var period: Int
        public var time: String
    }
}

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: HomeViewModel = .init()

    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]
    @State private var date: Date = .init()
    @State private var center: CGPoint = .zero
    @State private var refreshTick = 0

    func renderFeaturedGame(_ featured: Match) -> some View {
        NavigationLink {
            MatchView(featured, referrer: "home_featured")
        } label: {
            MatchOverview(
                game: featured,
                liveGame: viewModel.liveGame
            )
        }
        .buttonStyle(.scalePress)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear {
                    center = .init(x: geo.size.width / 2, y: geo.size.height / 2)
                }
        })
        .simultaneousGesture(TapGesture().onEnded {
            Task {
                PostHogSDK.shared.capture(
                    "featured_interaction",
                    properties: [
                        "game_id": featured.id,
                        "is_interested_team": await FeaturedGameContainsInterestedTeam(),
                    ],
                    userProperties: [
                        "interested_teams_count": Settings.shared.getInterestedTeamIds().count,
                    ]
                )
            }
        })
    }

    func FeaturedGameContainsInterestedTeam() async -> Bool {
        let interestedTeams = Settings.shared.getInterestedTeams()
        guard !interestedTeams.isEmpty else {
            return false
        }

        guard let featuredGame = viewModel.featuredGame else {
            return false
        }

        let interestedCodes = interestedTeams.map { $0.code.lowercased() }
        return interestedCodes.contains(featuredGame.homeTeam.code.lowercased()) ||
               interestedCodes.contains(featuredGame.awayTeam.code.lowercased())
    }

    func getTimeLoop() -> Double {
        let precision: Double = 10000
        return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(3*Int(precision))) / precision
    }

    private var upcomingMatches: [Match] {
        viewModel.latestMatches
            .filter { !$0.concluded }
            .sorted(by: { $0.date < $1.date })
    }

    // MARK: - Section Headers

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.title2.weight(.bold))
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Featured Game Header

    private var featuredHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Featured")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                    .textCase(.uppercase)
                    .kerning(1.2)
                Text("Today's Spotlight")
                    .font(.title2.weight(.bold))
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Calendar

    var matchCalendar: some View {
        VStack(spacing: 12) {
            sectionHeader("Match Calendar", systemImage: "calendar")

            if upcomingMatches.isEmpty {
                ContentUnavailableView(
                    "No upcoming matches",
                    systemImage: "calendar",
                    description: Text("Future games will appear here as they are scheduled.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    MatchCalendar(
                        matches: Array(upcomingMatches.prefix(5)),
                        liveMatches: viewModel.calendarLiveMatches
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Leaderboard

    var leaderboard: some View {
        VStack(spacing: 12) {
            sectionHeader("Standings", systemImage: "list.number")

            if viewModel.standingsDisabled {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Standings are temporarily unavailable.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
            } else if let standings = viewModel.standings {
                StandingsTable(
                    title: "Table",
                    items: standings,
                    favoriteTeamId: Settings.shared.getFavoriteTeamId()
                )
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Featured game
                VStack(spacing: 12) {
                    featuredHeader

                    if let featured = viewModel.featuredGame {
                        if #available(iOS 17.0, *) {
                            if featured.isLive() || viewModel.liveGame?.gameState == .ongoing || viewModel.liveGame?.gameState == .paused {
                                TimelineView(.animation) { _ in
                                    renderFeaturedGame(featured)
                                        .pulseShader(time: getTimeLoop(), center: center, speed: 150.0, amplitude: 0.1, decay: 5.0)
                                        .padding(.horizontal)
                                }
                            } else {
                                renderFeaturedGame(featured)
                                    .padding(.horizontal)
                            }
                        } else {
                            renderFeaturedGame(featured)
                                .padding(.horizontal)
                        }
                    } else {
                        // Skeleton placeholder
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(height: 110)
                            .overlay {
                                ProgressView()
                            }
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 4)

                matchCalendar

                leaderboard
            }
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
        .onChange(of: viewModel.featuredGame) { _, _ in
            guard let featured = viewModel.featuredGame else { return }
            viewModel.selectListenedGame(featured)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await viewModel.refresh(hard: true)
                }
            }
        }
        .refreshable {
            do {
                try await viewModel.refresh(hard: true)
                refreshTick &+= 1
            } catch let err {
                print("HomeView: Error refreshing: ", err)
            }
        }
        .sensoryFeedback(.success, trigger: refreshTick)
        .ignoresSafeArea(.container, edges: .horizontal)
    }

    func remainingTimeUntil(_ targetDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        let estimatedEndTimeString = formatter.string(from: targetDate)
        return estimatedEndTimeString
    }
}

extension HomeView {
    enum LeaguePages: Int, CaseIterable {
        case SHL
        case SDHL
    }
}

#Preview {
    HomeView()
}

#Preview("Dark") {
    HomeView()
        .preferredColorScheme(.dark)
}
