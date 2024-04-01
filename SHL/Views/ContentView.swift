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
    @State var gameListener: GameUpdater?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]
    
    @State private var selectedLeaderboard: LeaguePages = .SHL
    @State private var numberOfPages = LeaguePages.allCases.count
    
    @State private var debugOpen: Bool = false
    
    var body: some View {
        ScrollView {
            NavigationLink(destination: {
                MatchListView()
            }, label: {
                if let featured = SelectFeaturedMatch() {
                    MatchOverview(game: featured, liveGame: gameListener?.game)
                } else {
                    HStack {
                        
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                }
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        Text("Match Calendar")
                            .font(.title)
                        Spacer()
                    }
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(matchInfo.latestMatches.filter({!$0.played})) { match in
                                VStack(spacing: 6) {
                                    HStack {
                                        Image("Team/\(match.homeTeam.code)")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                        Spacer()
                                        VStack {
                                            Text(FormatDate(match.date))
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                            Text("vs.")
                                                .font(.callout)
                                            Spacer()
                                        }
                                        Spacer()
                                        Image("Team/\(match.awayTeam.code)")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                    }
                                    HStack {
                                        Spacer()
                                        Text(match.venue)
                                            .font(.footnote)
                                        Spacer()
                                    }
                                }
                                .padding(12)
                                .frame(width:200)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                    }
                    .padding(8)
                    .background(.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                
                VStack(spacing: 12) {
                    TabView(selection: $selectedLeaderboard) {
                        StandingsTable(title: "SHL", league: .SHL, dictionary: $leagueStandings.standings, onRefresh: {
                            let startTime = DispatchTime.now()
                            
                            if (await leagueStandings.fetchLeague(league: .SHL, skipCache: true, clearExisting: true)) != nil {
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
                            if (await leagueStandings.fetchLeague(league: .SDHL, skipCache: true, clearExisting: true)) != nil {
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
            Button("Debug") {
                debugOpen = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $debugOpen) {
                Capsule()
                    .fill(.primary)
                    .frame(width: 64, height: 6, alignment: .center)
                
                    .padding()
                DebugView()
            }
            
        }
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
            let oldGame = oldMatches.last(where: { IsLive($0) })
            guard let newGame = newMatches.last(where: { IsLive($0) }) else { return }
            
            guard oldGame?.id != newGame.id else {
                return
            }
            
            gameListener = GameUpdater(gameId: newGame.id)
        })
        .onChange(of: scenePhase, { _oldPhase, _newPhase in
            guard _newPhase == .active else {
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
            do {
                let startTime = DispatchTime.now()
                
                try await matchInfo.getLatest()
                let endTime = DispatchTime.now()
                let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let remainingTime = max(0, 1_000_000_000 - Int(nanoTime))
                
                gameListener?.refreshPoller()
                
                try await Task.sleep(nanoseconds: UInt64(remainingTime))
            } catch let _err {
                Logging.shared.log("This should be impossible, please report this issue \(_err)")
            }
        }
    }
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
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
