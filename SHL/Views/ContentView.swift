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
    
    @State private var date: Date = Date()
    @State private var center: CGPoint = .zero
    
    @State private var featuredGame: Game? = nil
    
    func renderFeaturedGame(_ featured: Game) -> some View {
        let content: some View = {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return AnyView(LargeOverview(game: featured, liveGame: gameListener?.game))
            } else {
                return AnyView(
                    MatchOverview(game: featured, liveGame: gameListener?.game)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                )
            }
        }()
        
        return NavigationLink(destination: {
            MatchView(match: featured)
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
    }

    
    func getTimeLoop() -> Double {
        let precision: Double = 10000
        if UIDevice.current.userInterfaceIdiom == .pad {
            return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(4*Int(precision)))/precision
        } else {
            return Double(Int((date.timeIntervalSinceNow * -1)*precision)%(3*Int(precision)))/precision
        }
    }
    
    var body: some View {
        ScrollView {
            if let featured = featuredGame {
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
                VStack(spacing: 8) {
                    HStack {
                        Text("Match Calendar")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        MatchCalendar(matches: Array(matchInfo.latestMatches.filter({ !$0.played }).prefix(5)))
                    }
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Leaderboard")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        Spacer()
                    }
                    
                    StandingsTable(title: "Table", standings: $leagueStandings.standings)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .onChange(of: matchInfo.latestMatches, perform: { oldMatches in
            let oldGame = oldMatches.last(where: { IsLive($0) })
            guard let newGame = matchInfo.latestMatches.last(where: { IsLive($0) }) else { return }
            
            guard oldGame?.id != newGame.id else {
                return
            }
            
            gameListener = GameUpdater(gameId: newGame.id)
        })
        .onChange(of: matchInfo.latestMatches, perform: { _ in
            Task {
                await SelectFeaturedMatch()
            }
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
                    let _ = try await leagueStandings.fetchLeague(skipCache: true)
                } catch let _err {
                    print(_err)
                }
                
                if let newGame = matchInfo.latestMatches.last(where: { IsLive($0) }) {
                    gameListener = GameUpdater(gameId: newGame.id)
                }
            }.value
        }
        .ignoresSafeArea(.container, edges: UIDevice.current.userInterfaceIdiom == .pad ? .all : .horizontal)
    }
    
    func ReformatStandings(_ standings: StandingResults) -> [StandingObj] {
        return standings.leagueStandings.map { standing in
            return StandingObj(id: UUID().uuidString, position: standing.Rank, logo: standing.info.teamInfo.teamMedia, team: standing.info.teamInfo.teamNames.long, teamCode: standing.info.code ?? "UNK", matches: String(standing.GP), diff: String(standing.Diff), points: String(standing.Points))
        }
    }
    
    func IsLive(_ game: Game) -> Bool {
        return !game.played && game.date < Date.now
    }
    
    func SelectFeaturedMatch() async {
        let scoredMatches = await scoreAndSortHockeyMatches(
            matchInfo.latestMatches,
            preferredTeam: Settings.shared.getPreferredTeam()
        )
        
        featuredGame = scoredMatches.first?.0
        /*let lastPlayed = matchInfo.latestMatches.last(where: { $0.played })
        
        if let lastInPast = matchInfo.latestMatches.last(where: { IsLive($0) }) {
            return lastInPast
        }
        
        if lastPlayed == nil,
           let firstInFuture = matchInfo.latestMatches.first {
            return firstInFuture
        }
        
        return lastPlayed*/
    }
    
    func getTeamByCode(_ code: String) async -> SiteTeam? {
        guard let teams = try? await TeamAPI.shared.getTeams() else { return nil }
        return teams.first(where: { $0.names.code == code })
    }
    
    func scoreAndSortHockeyMatches(_ matches: [Game], preferredTeam: String?) async -> [(Game, Double)] {
        // First, asynchronously get all team UUIDs
        let teamUUIDs = await withTaskGroup(of: (String, String).self) { group in
            for match in matches {
                group.addTask {
                    async let homeTeam = getTeamByCode(match.homeTeam.code)
                    let home = await homeTeam
                    return (match.homeTeam.code, home?.id ?? "")
                }
                group.addTask {
                    async let awayTeam = getTeamByCode(match.awayTeam.code)
                    let away = await awayTeam
                    return (match.awayTeam.code, away?.id ?? "")
                }
            }
            
            var uuidDict = [String: String]()
            for await (code, uuid) in group {
                uuidDict[code] = uuid
            }
            return uuidDict
        }
        
        // Now score the matches
        let scoredMatches = matches.map { game -> (Game, Double) in
            var score: Double = 0
            
            // Live games get the highest base score
            if game.isLive() {
                score += 1000
            }
            
            // Preferred team bonus
            if let preferredTeam = preferredTeam,
               let homeTeamUUID = teamUUIDs[game.homeTeam.code],
               let awayTeamUUID = teamUUIDs[game.awayTeam.code] {
                if homeTeamUUID == preferredTeam || awayTeamUUID == preferredTeam {
                    score += 500
                }
            }
            
            // Upcoming games score
            if !game.played {
                let timeUntilGame = game.date.timeIntervalSinceNow
                if timeUntilGame > 0 {
                    score += max(100 - log10(timeUntilGame / 3600) * 20, 0)
                }
            } else {
                // Played games score
                let timeSinceGame = -game.date.timeIntervalSinceNow
                score += max(50 - log10(timeSinceGame / 3600) * 10, 0)
            }
            
            return (game, score)
        }
        
        // Sort the matches based on their scores, highest to lowest
        return scoredMatches.sorted { $0.1 > $1.1 }
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
