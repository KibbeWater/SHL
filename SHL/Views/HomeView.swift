//
//  ContentView.swift
//  LHF
//
//  Created by KibbeWater on 12/30/23.
//

import ActivityKit
import ComposableArchitecture
import PostHog
import SHLCore
import SHLNetwork
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

    let store: StoreOf<HomeFeature>

    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]

    @State private var date: Date = .init()
    @State private var center: CGPoint = .zero

    init(store: StoreOf<HomeFeature>) {
        self.store = store
    }
    
    func renderFeaturedGame(_ featured: Match) -> some View {
        let content: some View = {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return AnyView(
                    LargeOverview(
                        game: featured,
                        liveGame: store.liveGame
                    )
                )
            } else {
                return AnyView(
                    MatchOverview(
                        game: featured,
                        liveGame: store.liveGame
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                )
            }
        }()
        
        return NavigationLink(destination: {
            MatchView(featured, referrer: "home_featured")
        }, label: {
            content
        })
        .buttonStyle(PlainButtonStyle())
        .background(GeometryReader { geo in
            Color(uiColor: .systemBackground)
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

        guard let featuredGame = store.featuredGame else {
            return false
        }

        let interestedCodes = interestedTeams.map { $0.code.lowercased() }
        return interestedCodes.contains(featuredGame.homeTeam.code.lowercased()) ||
               interestedCodes.contains(featuredGame.awayTeam.code.lowercased())
    }
    
    func getTimeLoop() -> Double {
        let precision: Double = 10000
        if UIDevice.current.userInterfaceIdiom == .pad {
            return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(4*Int(precision))) / precision
        } else {
            return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(3*Int(precision))) / precision
        }
    }
    
    private var upcomingMatches: [Match] {
        store.latestMatches
            .filter { !$0.played }
            .sorted(by: { $0.date < $1.date })
    }

    var matchCalendar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Match Calendar")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                Spacer()
            }

            if upcomingMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No upcoming matches")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    MatchCalendar(
                        matches: Array(upcomingMatches.prefix(5)),
                        liveMatches: store.calendarLiveMatches
                    )
                }
                .padding(.horizontal)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    var leaderboard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Leaderboard")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                Spacer()
            }
            
            if store.standingsDisabled {
                HStack {
                    Text("Standings are temporarily unavailable\nWe apologize for the inconvenience")
                        .font(.callout)
                    Spacer()
                }
                .padding(.horizontal)
            } else {
                if !store.standings.isEmpty {
                    StandingsTable(title: "Table", items: formatStandings(store.standings), favoriteTeamId: Settings.shared.getFavoriteTeamId())
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                } else {
                    ProgressView()
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            if let featured = store.featuredGame {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    renderFeaturedGame(featured)
                } else {
                    if #available(iOS 17.0, *) {
                        if featured.isLive() || store.liveGame?.gameState == .ongoing || store.liveGame?.gameState == .paused {
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
                }
            } else {
                HStack {}
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    .padding(.horizontal)
            }
            
            VStack(spacing: 24) {
                matchCalendar

                leaderboard
            }
            .padding(.top)
        }
        .onChange(of: store.featuredGame) { _, newFeatured in
            guard let featured = newFeatured else { return }
            store.send(.featuredGameSelected(featured))
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.send(.refreshed)
            }
        }
        .refreshable {
            store.send(.refreshed)
        }
        .onAppear {
            store.send(.onAppear)
        }
        .ignoresSafeArea(
            .container,
            edges: UIDevice.current.userInterfaceIdiom == .pad ? .all : .horizontal
        )
    }
    
    func remainingTimeUntil(_ targetDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        let estimatedEndTimeString = formatter.string(from: targetDate)
        return estimatedEndTimeString
    }

    private func formatStandings(_ standings: [Standings]) -> [StandingObj] {
        return standings.map { standing in
            let gd = standing.goalDifference
            let diffStr = gd > 0 ? "+\(gd)" : String(gd)
            return StandingObj(
                id: standing.id,
                teamId: standing.team.id,
                position: standing.rank,
                team: standing.team.name,
                teamCode: standing.team.code,
                gamesPlayed: standing.gamesPlayed,
                wins: standing.wins,
                overtimeWins: standing.overtimeWins,
                losses: standing.losses,
                overtimeLosses: standing.overtimeLosses,
                diff: diffStr,
                points: String(standing.points),
                teamObj: standing.team
            )
        }
    }
}

extension HomeView {
    enum LeaguePages: Int, CaseIterable {
        case SHL
        case SDHL
    }
}

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State()) {
        HomeFeature()
    })
}
