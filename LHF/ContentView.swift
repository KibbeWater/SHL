//
//  ContentView.swift
//  LHF
//
//  Created by user242911 on 12/30/23.
//

import UIKit
import SwiftUI
import HockeyKit

struct PageControlView<T: RawRepresentable>: UIViewRepresentable where T.RawValue == Int {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var currentPage: T
    @Binding var numberOfPages: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context)
    -> UIPageControl {
        let uiView = UIPageControl()
        uiView.pageIndicatorTintColor = colorScheme == .dark ? nil : .black.withAlphaComponent(0.2)
        uiView.currentPageIndicatorTintColor = colorScheme == .dark ? nil : .black
        uiView.backgroundStyle = .automatic
        uiView.currentPage = currentPage.rawValue
        uiView.numberOfPages = numberOfPages
        uiView.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged), for: .valueChanged)
        return uiView
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentPage.rawValue
        uiView.numberOfPages = numberOfPages
        updateColors(uiView)
    }
    
    private func updateColors(_ uiView: UIPageControl) {
            uiView.pageIndicatorTintColor = colorScheme == .dark ? nil : .black.withAlphaComponent(0.2)
            uiView.currentPageIndicatorTintColor = colorScheme == .dark ? nil : .black
            uiView.backgroundStyle = .automatic
        }
}

extension PageControlView {
    final class Coordinator: NSObject {
        var parent: PageControlView
        
        init(_ parent: PageControlView) {
            self.parent = parent
        }
        
        @objc func valueChanged(sender: UIPageControl) {
            guard let currentPage = T(rawValue: sender.currentPage) else {
                return
            }

            withAnimation {
                parent.currentPage = currentPage
            }
        }
    }
}

public struct LiveGame {
    public var id: String
    public var homeTeam: LiveTeam
    public var awayTeam: LiveTeam
    public var time: LiveTime
    
    init (game: Game) {
        self.id = game.id
        self.homeTeam = LiveTeam(name: game.homeTeam.name, code: game.homeTeam.code, icon: game.homeTeam.logo, score: game.homeTeam.result)
        self.awayTeam = LiveTeam(name: game.awayTeam.name, code: game.awayTeam.code, icon: game.awayTeam.logo, score: game.awayTeam.result)
        self.time = LiveTime(period: 0, time: "00:00")
    }
    
    public struct LiveTeam {
        public var name: String
        public var code: String
        public var icon: String
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
    @State var gamePoller: GamePoller?
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]
    
    @State private var liveGame: GameOverview? = nil
    
    @State private var selectedLeaderboard: LeaguePages = .SHL
    @State private var numberOfPages = LeaguePages.allCases.count
    
    @State private var debugOpen: Bool = false
    
    var body: some View {
        ScrollView {
            if let lastPlayed = SelectFeaturedMatch() {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        ForEach(matchInfo.latestMatches.filter({!$0.played})) { match in
                            VStack {
                                Text(FormatDate(match.date))
                                    .font(.footnote)
                                Text(match.date.formatted(date: .omitted, time: .shortened))
                                    .font(.footnote)
                            }
                            .onAppear {
                                Logging.shared.log("[ContentView] Date: \(match.date.ISO8601Format())    Formatted: \(FormatDate(match.date))")
                            }
                            
                            .padding(.vertical, 6)
                            Spacer()
                            
                        }
                    }
                    .background(.secondary.opacity(0.4))
                    
                    HStack {
                        VStack {
                            SVGImageView(url: URL(string: lastPlayed.homeTeam.logo)!, size: CGSize(width: 50, height: 50))
                                .frame(width: 50, height: 50)
                            if let _live = liveGame {
                                Text("\(_live.homeGoals)")
                            } else {
                                Text("\(lastPlayed.homeTeam.result)")
                            }
                        }
                        
                        Spacer()
                        VStack {
                            HStack {
                                if let _live = liveGame {
                                    if _live.state == .ongoing {
                                        Text("P\(_live.time.period)")
                                        Text("-")
                                        Text("\(_live.time.periodTime) \(Image(systemName: "clock"))")
                                    }
                                    
                                    if let _endDate = _live.time.periodEnd {
                                        TimelineView(.periodic(from: .now, by: 1)) { context in
                                            Text(_endDate, style: .timer)
                                        }
                                    }
                                } else {
                                    if !IsLive(lastPlayed) {
                                        Text("Played on \(lastPlayed.date.formatted(date: .abbreviated, time: .omitted))")
                                    }
                                }
                            }
                            if let _live = liveGame {
                                if let _endDate = _live.time.periodEnd {
                                    Text(RemainingTimeUntil(_endDate))
                                }
                            }
                            if let _live = liveGame {
                                switch _live.state {
                                case .starting:
                                    Text("Starting")
                                        .fontWeight(.bold)
                                case .overtime:
                                    Text("Overtime")
                                        .fontWeight(.bold)
                                case .ongoing:
                                    HStack {
                                        Text("LIVE")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.red)
                                    }
                                case .onbreak:
                                    Text("Paused")
                                        .fontWeight(.bold)
                                case .ended:
                                    Text("ENDED")
                                        .fontWeight(.bold)
                                }
                            } else {
                                if IsLive(lastPlayed) {
                                    Text("LIVE")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Spacer()
                        
                        VStack {
                            SVGImageView(url: URL(string: lastPlayed.awayTeam.logo)!, size: CGSize(width: 50, height: 50))
                                .frame(width: 50, height: 50)
                            if let _live = liveGame {
                                Text("\(_live.awayGoals)")
                            } else {
                                Text("\(lastPlayed.awayTeam.result)")
                            }
                        }
                    }
                    .padding()
                    .background(IsLive(lastPlayed) && (liveGame?.state != .ended && liveGame != nil) ? nil : (liveGame?.homeGoals ?? lastPlayed.homeTeam.result > liveGame?.awayGoals ?? lastPlayed.awayTeam.result ? LinearGradient(gradient: Gradient(colors: [.green, .red]), startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.4) : LinearGradient(gradient: Gradient(colors: [.green, .red]), startPoint: .topTrailing, endPoint: .bottomLeading).opacity(0.4)))
                    
                    VStack {
                        HStack {
                            Text("Match Dates")
                                .multilineTextAlignment(.leading)
                                .font(.title)
                            Spacer()
                        }
                        ScrollView(.horizontal) {
                            VStack {
                                Text("Luleå Coop Arena")
                                    .font(.footnote)
                            }
                        }
                        .padding()
                        .background(.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                    
                    VStack(spacing: 12) {
                        TabView(selection: $selectedLeaderboard) {
                            StandingsTable(title: "SHL", league: .SHL, dictionary: $leagueStandings.standings, onRefresh: {
                                let startTime = DispatchTime.now()
                                
                                if let _standings = await leagueStandings.fetchLeague(league: .SHL, skipCache: true, clearExisting: true) {
                                    do {
                                        let endTime = DispatchTime.now()
                                        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                                        let remainingTime = max(0, 1_000_000_000 - Int(nanoTime))
                                        
                                        try await Task.sleep(nanoseconds: UInt64(remainingTime))
                                    } catch {
                                        fatalError("Should be impossible")
                                    }
                                }
                            })
                            .padding(.horizontal)
                            .tag(LeaguePages.SHL)
                            
                            StandingsTable(title: "SDHL", league: .SDHL, dictionary: $leagueStandings.standings, onRefresh: {
                                let startTime = DispatchTime.now()
                                if let _standings = await leagueStandings.fetchLeague(league: .SDHL, skipCache: true, clearExisting: true) {
                                    do {
                                        let endTime = DispatchTime.now()
                                        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                                        let remainingTime = max(0, 1_000_000_000 - Int(nanoTime))
                                        
                                        try await Task.sleep(nanoseconds: UInt64(remainingTime))
                                    } catch {
                                        fatalError("Should be impossible")
                                    }
                                }
                            })
                            .padding(.horizontal)
                            .tag(LeaguePages.SDHL)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 350)
                        PageControlView(currentPage: $selectedLeaderboard, numberOfPages: .constant(2))
                            .frame(maxWidth: 0, maxHeight: 0)
                            .padding(.top, 12)
                    }
                    .padding(.vertical)
                }
            }
            Button("Debug") {
                debugOpen = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $debugOpen, content: {
                Capsule()
                    .fill(.primary)
                    .frame(width: 64, height: 6, alignment: .center)
                
                    .padding()
                DebugView()
            })
            
        }
        .padding(.vertical)
        .onAppear {
            Task {
                do {
                    try await matchInfo.getLatest()
                } catch {
                    fatalError("This should be impossible, please report this issue")
                }
            }
            Task {
                leagueStandings.fetchLeagues(skipCache: true)
            }
        }
        .onChange(of: matchInfo.latestMatches, { oldMatches, newMatches in
            /*gamePoller = GamePoller(url: URL(string: "https://game-broadcaster.s8y.se/live/game")!, gameId: "qcz-3SKH6QA9t") { _game, _err in
                GameUpdate(game: _game, err: _err)
            }*/
            
            let oldGame = oldMatches.last(where: { IsLive($0) })
            guard let newGame = newMatches.last(where: { IsLive($0) }) else { return }
            
            guard oldGame?.id != newGame.id else {
                return
            }
            
            gamePoller = GamePoller(url: URL(string: "https://game-broadcaster.s8y.se/live/game")!, gameId: newGame.id, dataReceivedCallback: { _game, _err in
                GameUpdate(game: _game, err: _err)
            })
        })
        .refreshable {
            do {
                let startTime = DispatchTime.now()
                
                if let _poller = gamePoller {
                    gamePoller = GamePoller(url: URL(string: "https://game-broadcaster.s8y.se/live/game")!, gameId: _poller.matchId, dataReceivedCallback: { _game, _err in
                        GameUpdate(game: _game, err: _err)
                    })
                }
                
                liveGame = nil
                
                try await matchInfo.getLatest()
                let endTime = DispatchTime.now()
                let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let remainingTime = max(0, 1_000_000_000 - Int(nanoTime))
                
                try await Task.sleep(nanoseconds: UInt64(remainingTime))
            } catch {
                fatalError("This should be impossible, please report this issue")
            }
        }
    }
    
    func GameUpdate(game: GameEvent?, err: Error?) {
        guard err == nil else {
            return
        }
        guard let _game = game?.game.gameOverview else { return }
        guard _game.gameUuid == gamePoller?.matchId else {
            return
        }
        
        DispatchQueue.main.async {
            liveGame = _game
        }
        
    }
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
    }
    
    func ReformatStandings(_ standings: StandingResults) -> [StandingObj] {
        return standings.leagueStandings.map { standing in
            return StandingObj(id: UUID().uuidString, position: standing.Rank, logo: standing.info.teamInfo.teamMedia, team: standing.info.teamInfo.teamNames.long, matches: String(standing.GP), diff: String(standing.Diff), points: String(standing.Points))
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
