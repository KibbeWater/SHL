//
//  TeamView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 28/9/24.
//

import HockeyKit
import Kingfisher
import SwiftUI

private enum TeamTabs: String, CaseIterable {
    case history = "History"
    case lineup = "Lineup"
}

struct TeamView: View {
    @StateObject var viewModel: TeamViewModel

    @State var teamColor: Color = .black
    @State private var selectedTab: TeamTabs = .history
    
    let team: Team
    
    init(team: Team) {
        self.team = team
        self._viewModel = .init(wrappedValue: .init(team))
    }
    
    func loadTeamColors() {
        team.getTeamColor { _color in
            teamColor = _color
        }
    }
    
    var matchHistoryTab: some View {
        LazyVStack {
            let upcomingGames = viewModel.history.filter { !$0.played }.reversed()
            let playedGames = viewModel.history.filter { $0.played }
            
            if viewModel.history.isEmpty {
                VStack {
                    ProgressView()
                }
            } else {
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
                                    MatchView(match, referrer: "team_view")
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
                                    MatchView(match, referrer: "team_view")
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
                    VStack {
                        HStack {
                            Text("Upcoming Games")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVStack {
                            ForEach(upcomingGames.prefix(3), id: \.id) { match in
                                NavigationLink {
                                    MatchView(match, referrer: "team_view")
                                } label: {
                                    MatchOverview(game: match)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.top)
                    VStack {
                        HStack {
                            Text("Played Games")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVStack {
                            ForEach(playedGames, id: \.id) { match in
                                NavigationLink {
                                    MatchView(match, referrer: "team_view")
                                } label: {
                                    MatchOverview(game: match)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
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
    
    func playerCountryColor(_ player: Player) -> LinearGradient {
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
        case .none, .unknown:
            return LinearGradient(colors: [.gray, .gray], startPoint: .top, endPoint: .bottom)
        }
    }
    
    var lineupTab: some View {
        Group {
            if !viewModel.lineup.isEmpty {
                // Filter concrete arrays for each position
                let goalkeepers: [Player] = viewModel.lineup.filter { $0.position == .goalkeeper }
                let defenders: [Player] = viewModel.lineup.filter { $0.position == .defense }
                let forwards: [Player] = viewModel.lineup.filter { $0.position == .forward }

                VStack(alignment: .leading, spacing: 16) {
                    // Goalkeepers
                    if !goalkeepers.isEmpty {
                        VStack(alignment: .leading) {
                            Text(lineupName(.goalkeeper))
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(goalkeepers, id: \.id) { player in
                                        renderPlayerCard(player)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Defenders
                    if !defenders.isEmpty {
                        VStack(alignment: .leading) {
                            Text(lineupName(.defense))
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(defenders, id: \.id) { player in
                                        renderPlayerCard(player)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Forwards
                    if !forwards.isEmpty {
                        VStack(alignment: .leading) {
                            Text(lineupName(.forward))
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(forwards, id: \.id) { player in
                                        renderPlayerCard(player)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            } else {
                VStack { ProgressView() }
            }
        }
    }
    
    func renderPlayerCard(_ player: Player) -> some View {
        return LazyVStack {
            if let url = player.portraitURL {
                NavigationLink {
                    PlayerView(player, teamColor: $teamColor)
                } label: {
                    VStack {
                        Text(player.fullName)
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(uiColor: .label))
                        
                        KFImage(.init(string: url)!)
                            .placeholder {
                                ProgressView()
                                    .frame(width: 200)
                            }
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(
                                width: 186,
                                height: 224
                            )))
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
                    }
                    .frame(height: 256)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        Text(team.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        if let pos = viewModel.standings.first(where: { $0.team.code == team.code }) {
                            Text("#\(pos.rank)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    TeamLogoView(team: team, size: .large)
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
            .refreshable {
                try? await viewModel.refresh()
            }
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.refresh()
                } catch let err {
                    print(err)
                }
            }

            loadTeamColors()
        }
    }
}

#Preview {
    TeamView(team: .fakeData())
        .environment(\.hockeyAPI, HockeyAPI())
}
