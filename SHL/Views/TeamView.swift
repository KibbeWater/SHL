//
//  TeamView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 28/9/24.
//

import SwiftUI
import HockeyKit

private enum TeamTabs: String, CaseIterable {
    case history = "History"
    case lineup = "Lineup"
}

struct TeamView: View {
    @EnvironmentObject private var leagueStandings: LeagueStandings
    @EnvironmentObject private var matchInfo: MatchInfo
    
    @State var teamColor: Color = .black
    @State private var selectedTab: TeamTabs = .history
    
    @State private var matchHistory: [Game] = []
    @State var lineup: [TeamLineup] = []
    
    let team: SiteTeam
    
    init(team: SiteTeam) {
        self.team = team
    }
    
    func loadTeamColors() {
        team.getTeamColor { _color in
            teamColor = _color
        }
    }
    
    func loadLineups() async {
        do {
            let _lineup = try await TeamAPI.shared.getLineup(team)
            lineup = _lineup
        } catch let _err {
            print("Failed to fetch lineups")
            print(_err)
        }
    }
    
    var matchHistoryTab: some View {
        VStack {
            let upcomingGames = matchHistory.filter({ !$0.played })
            let playedGames = matchHistory.filter({ $0.played })
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                VStack {
                    VStack {
                        HStack {
                            Text("Played Games")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(playedGames.prefix(3), id: \.id) { match in
                            NavigationLink {
                                MatchView(match: match)
                            } label: {
                                MatchOverview(game: match)
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                    }
                    VStack {
                        HStack {
                            Text("Upcoming Games")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(upcomingGames, id: \.id) { match in
                            NavigationLink {
                                MatchView(match: match)
                            } label: {
                                MatchOverview(game: match)
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)

                            }
                        }
                    }
                    .padding(.top)
                }
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            } else {
                ForEach(matchHistory, id: \.id) { match in
                    MatchOverview(game: match)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
            }
        }
    }
    
    func lineupName(_ position: PositionCode) -> String {
        switch position {
        case .defense:
            return "Defense"
        case .forward:
            return "Forward"
        case .goalkeeper:
            return "Goalkeeper"
        }
    }
    
    func playerCountryColor(_ player: LineupPlayer) -> LinearGradient {
        switch player.nationality {
        case .sweden:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .top, endPoint: .bottom)
        case .finland:
            return LinearGradient(colors: [.white, .blue], startPoint: .top, endPoint: .bottom)
        case .canada:
            return LinearGradient(colors: [.red, .white], startPoint: .top, endPoint: .bottom)
        case .usa:
            return LinearGradient(colors: [.red, .blue], startPoint: .top, endPoint: .bottom)
        case .norway:
            return LinearGradient(colors: [.red, .white, .blue], startPoint: .top, endPoint: .bottom)
        case .unknown(_):
            return LinearGradient(colors: [.gray, .gray], startPoint: .top, endPoint: .bottom)
        }
    }
    
    var lineupTab: some View {
        ForEach(lineup, id: \.position) { line in
            VStack(alignment: .leading) {
                Text(lineupName(line.positionCode))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(line.players, id: \.fullName) { player in
                            if let url = player.renderedLatestPortrait?.url {
                                
                                NavigationLink {
                                    PlayerView(player: player, teamColor: $teamColor)
                                } label: {
                                    VStack {
                                        Text(player.fullName)
                                            .padding(.horizontal, 4)
                                            .padding(.top, 8)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color(uiColor: .label))
                                        
                                        CacheAsyncImage(url: .init(string: url)!) { _img in
                                            _img
                                                .resizable()
                                                .background(playerCountryColor(player))
                                                .aspectRatio(contentMode: .fit)
                                                .overlay(alignment: .topLeading) {
                                                    if let _number = player.jerseyNumber {
                                                        Text("#\(_number)")
                                                            .padding(.all, 8)
                                                            .foregroundStyle(Color(uiColor: .label))
                                                    }
                                                }
                                        } placeholder: {
                                            Spacer()
                                            ProgressView()
                                                .frame(width: 200)
                                            Spacer()
                                        }
                                    }
                                    .frame(height: 256)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                teamColor,
                .clear,
                .clear,
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        Text(team.names.longSite ?? team.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        if let pos = leagueStandings.standings?.cacheItem.leagueStandings.first(where: {$0.info.code == team.names.code}) {
                            Text("#\(pos.Rank)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    Image("Team/\(team.names.code.uppercased())")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                VStack {
                    HStack {
                        Spacer()
                        ForEach(TeamTabs.allCases, id: \.self) { tab in
                            Button(tab.rawValue) {
                                selectedTab = tab
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .buttonStyle(.plain)
                            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                            Spacer()
                        }
                    }
                    
                    VStack {
                        switch selectedTab {
                        case .history:
                            matchHistoryTab
                        case .lineup:
                            lineupTab
                        }
                    }
                    .padding(.top)
                }
                .padding(.top, 52)
            }
        }
        .task {
            if let _season = try? await matchInfo.getCurrentSeason() {
                guard let schedule = try? await matchInfo.getSchedule(_season, team: team.id) else { return }
                matchHistory = schedule.gameInfo.map({ $0.toGame() })
            }
        }
        .onAppear {
            loadTeamColors()
            Task {
                await loadLineups()
            }
        }
    }
}

#Preview {
    TeamView(team: .fakeData())
        .environmentObject(LeagueStandings())
        .environmentObject(MatchInfo())
}