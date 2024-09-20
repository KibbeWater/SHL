//
//  ContentView.swift
//  LHF
//
//  Created by KibbeWater on 12/30/23.
//

import SwiftUI
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

struct ContentView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    @EnvironmentObject var leagueStandings: LeagueStandings
    @State var gameListener: GameUpdater?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]
    
    @State private var selectedLeaderboard: LeaguePages = .SHL
    @State private var numberOfPages = LeaguePages.allCases.count
    
    @State private var date: Date = Date()
    @State private var center: CGPoint = .zero
    
    func renderFeaturedGame(_ featured: Game) -> some View {
        return NavigationLink(destination: {
                MatchView(match: featured)
            }, label: {
                MatchOverview(game: featured, liveGame: gameListener?.game)
            })
            .buttonStyle(PlainButtonStyle())
            .background(GeometryReader { geo in
                Color(uiColor: .systemBackground)
                    .onAppear {
                        center = .init(x: geo.size.width/2, y: geo.size.height/2)
                    }
            })
        
    }
    
    func getTimeLoop() -> Double {
        let precision: Double = 10000
        return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(3*Int(precision)))/precision
    }
    
    var body: some View {
        ScrollView {
            if let featured = SelectFeaturedMatch() {
                if #available(iOS 17.0, *) {
                    if featured.isLive() {
                        TimelineView(.animation) { _ in
                            renderFeaturedGame(featured)
                                .pulseShader(time: getTimeLoop(), center: center, speed: 150.0, amplitude: 0.1, decay: 5.0)
                                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                                .padding(.horizontal)
                        }
                    } else {
                        renderFeaturedGame(featured)
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .padding(.horizontal)
                    }
                } else {
                    renderFeaturedGame(featured)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        .padding(.horizontal)
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
            
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        NavigationLink {
                            MatchListView()
                        } label: {
                            Text("Match Calendar \(Image(systemName: "chevron.right"))")
                                .font(.title)
                        }
                        .padding(.horizontal)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        MatchCalendar(matches: Array(matchInfo.latestMatches.prefix(5)))
                    }
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical)

                StandingsTable(title: "Table", league: .SHL, dictionary: $leagueStandings.standings)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
            }
        }
        .onChange(of: matchInfo.latestMatches, perform: { oldMatches in
            let oldGame = oldMatches.last(where: { IsLive($0) })
            guard let newGame = matchInfo.latestMatches.last(where: { IsLive($0) }) else { return }
            
            guard oldGame?.id != newGame.id else {
                return
            }
            
            gameListener = GameUpdater(gameId: newGame.id)
        })
        .onChange(of: scenePhase, perform: { _ in
            guard scenePhase == .active else {
                return
            }
            
            gameListener?.refreshPoller()
            Task {
                do {
                    try await matchInfo.getLatest()
                } catch {
                    print("Unable to refresh")
                }
            }
        })
        .refreshable {
            await Task {
                do {
                    try await matchInfo.getLatest()
                    let _ = try await leagueStandings.fetchLeague(league: .SHL, skipCache: true)
                } catch let _err {
                    print(_err)
                }
                
                if let newGame = matchInfo.latestMatches.last(where: { IsLive($0) }) {
                    gameListener = GameUpdater(gameId: newGame.id)
                }
            }.value
        }
    }
    
    func ReformatStandings(_ standings: StandingResults) -> [StandingObj] {
        return standings.leagueStandings.map { standing in
            return StandingObj(id: UUID().uuidString, position: standing.Rank, logo: standing.info.teamInfo.teamMedia, team: standing.info.teamInfo.teamNames.long, teamCode: standing.info.code ?? "UNK", matches: String(standing.GP), diff: String(standing.Diff), points: String(standing.Points))
        }
    }
    
    func IsLive(_ game: Game) -> Bool {
        return !game.played && game.date < Date.now
    }
    
    func SelectFeaturedMatch() -> Game? {
        let lastPlayed = matchInfo.latestMatches.last(where: { $0.played })
        
        if let lastInPast = matchInfo.latestMatches.last(where: { IsLive($0) }) {
            return lastInPast
        }
        
        if lastPlayed == nil,
           let firstInFuture = matchInfo.latestMatches.first {
            return firstInFuture
        }
        
        return lastPlayed
    }
    
    func RemainingTimeUntil(_ targetDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        let estimatedEndTimeString = formatter.string(from: targetDate)
        return estimatedEndTimeString
    }
}

extension ContentView {
    enum LeaguePages: Int, CaseIterable {
        case SHL
        case SDHL
    }
}

#Preview {
    ContentView()
        .environmentObject(MatchInfo())
        .environmentObject(LeagueStandings())
}
