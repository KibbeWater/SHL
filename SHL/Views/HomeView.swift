//
//  ContentView.swift
//  LHF
//
//  Created by KibbeWater on 12/30/23.
//

import SwiftUI
import PostHog
import HockeyKit
import ActivityKit

public struct LiveGame {
    public var id: String
    public var homeTeam: LiveTeam
    public var awayTeam: LiveTeam
    public var time: LiveTime
    
    init (game: Game) {
        self.id = game.id
        self.homeTeam = LiveTeam(name: game.homeTeam.name, code: game.homeTeam.code, score: game.homeTeam.result)
        self.awayTeam = LiveTeam(name: game.awayTeam.name, code: game.awayTeam.code, score: game.awayTeam.result)
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
    
    @Environment(\.hockeyAPI) private var hockeyApi: HockeyAPI
    
    @StateObject private var viewModel: HomeViewModel = HomeViewModel()
    
    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]
    
    @State private var date: Date = Date()
    @State private var center: CGPoint = .zero
    
    func renderFeaturedGame(_ featured: Game) -> some View {
        let content: some View = {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return AnyView(
                    LargeOverview(
                        game: featured,
                        liveGame: viewModel.liveGame?.gameOverview
                    )
                )
            } else {
                return AnyView(
                    MatchOverview(
                        game: featured,
                        liveGame: viewModel.liveGame?.gameOverview
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
                        "is_preferred_team": await FeaturedGameContainsPreferredTeam(),
                    ],
                    userProperties: [
                        "preferred_team": Settings.shared.getPreferredTeam() ?? "N/A"
                    ]
                )
            }
        })
    }
    
    func FeaturedGameContainsPreferredTeam() async -> Bool {
        guard let preferredId = Settings.shared.getPreferredTeam() else {
            return false
        }
        
        guard let featuredGame = viewModel.featuredGame else {
            return false
        }
        
        guard let preferredTeam = try? await hockeyApi.team.getTeam(withId: preferredId) else {
            return false
        }
        
        return featuredGame.homeTeam.code.lowercased() == preferredTeam.teamNames.code.lowercased() || featuredGame.awayTeam.code.lowercased() == preferredTeam.teamNames.code.lowercased()
    }
    
    func getTimeLoop() -> Double {
        let precision: Double = 10000
        if UIDevice.current.userInterfaceIdiom == .pad {
            return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(4*Int(precision)))/precision
        } else {
            return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(3*Int(precision)))/precision
        }
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
            
            VStack(spacing: 12) {
                MatchCalendar(
                    matches: Array(viewModel.latestMatches
                        .filter({ !$0.played })
                        .sorted(by: { $0.date < $1.date })
                        .prefix(5)
                    )
                )
            }
            .padding(.horizontal)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            
            if viewModel.standingsDisabled {
                HStack {
                    Text("Standings are disabled during finals\nWe apologize for the inconvenience")
                        .font(.callout)
                    Spacer()
                }
                .padding(.horizontal)
            } else {
                if let standings = viewModel.standings {
                    StandingsTable(title: "Table", items: standings)
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
            if let featured = viewModel.featuredGame {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    renderFeaturedGame(featured)
                } else {
                    if #available(iOS 17.0, *) {
                        if featured.isLive() {
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
                HStack {
                    
                }
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
        .onChange(of: viewModel.featuredGame) { _, _ in
            guard let featured = viewModel.featuredGame else { return }
            viewModel.selectListenedGame(featured)
        }
        .onChange(of: scenePhase) { _, _ in
            hockeyApi.listener.connect()
        }
        .refreshable {
            try? await viewModel.refresh()
        }
        .onAppear {
            viewModel.setAPI(hockeyApi)
            Task {
                try? await viewModel.refresh()
            }
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
}

extension HomeView {
    enum LeaguePages: Int, CaseIterable {
        case SHL
        case SDHL
    }
}

#Preview {
    HomeView()
        .environment(\.hockeyAPI, HockeyAPI())
}
