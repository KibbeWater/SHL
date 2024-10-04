//
//  PlayerView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/9/24.
//

import SwiftUI
import HockeyKit

private enum PlayerTabs: String, CaseIterable {
    case statistics = "Statistics"
    case history = "History"
}

struct PlayerView: View {
    let player: LineupPlayer
    @Binding var teamColor: Color
    
    @State private var playerInfo: Player? = nil
    @State private var seasonStats: PlayerGameLog? = nil
    
    @State private var selectedTab: PlayerTabs = .statistics

    func loadPlayerInfo() async {
        self.playerInfo = try? await PlayerAPI.shared.getPlayer(id: player.uuid)
    }
    
    func loadAdditionalStats() async {
        do {
            self.seasonStats = try await playerInfo?.getSeasonStats()
        } catch let _err {
            print("Error fetching additional stats:")
            print(_err)
        }
    }
    
    var statisticsTab: some View {
        GeometryReader { geo in
            LazyVGrid(columns: [
                .init(.flexible(minimum: 10, maximum: geo.size.width)),
                .init(.flexible(minimum: 10, maximum: geo.size.width)),
            ]) {
                if let GAA = playerInfo?.getStats(for: .goalsPerHour) {
                    VStack {
                        Text(String(GAA))
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Goals / h")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let GPI = playerInfo?.getStats(for: .matches) {
                    VStack {
                        Text(String(Int(GPI)))
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Games")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let SVS = playerInfo?.getStats(for: .saves) {
                    VStack {
                        Text(String(Int(SVS)))
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Saves")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let SVSPerc = playerInfo?.getStats(for: .saves) {
                    VStack {
                        Text("\(Int(SVSPerc))%")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Saves %")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal)
    }
    
    var historyTab: some View {
        VStack {
            if let stats = seasonStats?.stats {
                let grouping = stats.groupBy(keySelector: { $0.season })
                ForEach(grouping.keys.sorted(by: >), id: \.self) { seasonStat in
                    let item = grouping[seasonStat]!
                    VStack {
                        HStack {
                            Text(String(seasonStat))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        VStack(spacing: 24) {
                            ForEach(item, id: \.self) { stat in
                                HStack {
                                    VStack {
                                        Image("Team/\(stat.info.teamId.uppercased())")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 46, height: 46)
                                    }
                                    .padding(.trailing, 12)
                                    VStack {
                                        VersusBar("\(String(stat.gamesPlayed)) matches (W/L)", homeSide: stat.wins, awaySide: stat.losses, homeColor: .blue, awayColor: .red)
                                            .fontWeight(.medium)
                                    }
                                    Spacer()
                                }
                                .frame(height: 52)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(alignment: .topTrailing, content: {
                                    switch stat.gameType {
                                    case .regular:
                                        Text("SHL")
                                            .foregroundStyle(.secondary)
                                            .fontWeight(.semibold)
                                            .font(.system(size: 12))
                                            .padding(.horizontal, 16)
                                            .padding(.top, 4)
                                    case .finals:
                                        Text("Finals")
                                            .foregroundStyle(.secondary)
                                            .fontWeight(.semibold)
                                            .font(.footnote)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 4)
                                    case .unknown:
                                        Text("Unknown")
                                            .foregroundStyle(.secondary)
                                            .fontWeight(.semibold)
                                            .font(.footnote)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 4)
                                    }
                                })
                            }
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
            } else {
                ProgressView()
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
                        Text(player.fullName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        HStack {
                            if let jerseyNumber = player.jerseyNumber {
                                Text(String(jerseyNumber))
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .frame(height: 22)
                                if let playerInfo {
                                    Text(playerInfo.position)
                                        .fontWeight(.medium)
                                } else {
                                    ProgressView()
                                }
                                Divider()
                                    .frame(height: 22)
                            }
                            if let playerInfo {
                                Image("Team/\(playerInfo.team.code.uppercased())")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)
                                Text(playerInfo.team.name)
                            } else {
                                ProgressView()
                            }
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if let _url = player.renderedLatestPortrait?.url {
                        AsyncImage(url: .init(string: _url)!) { img in
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 72)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 72, height: 72)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                
                VStack {
                    HStack {
                        Spacer()
                        ForEach(PlayerTabs.allCases, id: \.self) { tab in
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
                        case .statistics:
                            statisticsTab
                        case .history:
                            historyTab
                        }
                    }
                    .padding(.top)
                }
                .padding(.top, 52)
            }
        }
        .onChange(of: playerInfo) { _ in
            Task {
                await loadAdditionalStats()
            }
        }
        .onAppear {
            Task {
                await loadPlayerInfo()
            }
        }
    }
}

#Preview {
    PlayerView(player: .fakeData(), teamColor: .constant(.black))
}
