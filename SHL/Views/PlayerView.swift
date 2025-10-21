//
//  PlayerView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/9/24.
//

import HockeyKit
import Kingfisher
import SwiftUI

private enum PlayerTabs: String, CaseIterable {
    case statistics = "Statistics"
    case history = "History"
}

struct PlayerView: View {
    @Environment(\.hockeyAPI) private var api: HockeyAPI
    
    @StateObject private var viewModel: PlayerViewModel

    let player: Player
    
    @Binding var teamColor: Color
    
    @State private var selectedTab: PlayerTabs = .statistics
    
    init(_ player: Player, teamColor: Binding<Color>) {
        self.player = player
        self._teamColor = teamColor
        self._viewModel = .init(wrappedValue: .init(player))
    }

    var statisticsTab: some View {
        VStack {
            Text("Player statistics coming soon")
                .foregroundColor(.secondary)
                .padding()
        }
        // TODO: Aggregate statistics are not available from the new backend API yet
        // Will need to either calculate from game logs or wait for backend support
    }
    
    func getHistoryStat(stat: String, item: [PlayerGameLog]) -> some View {
        return VStack {
            HStack {
                Text(String(stat))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                Spacer()
            }
            VStack(spacing: 24) {
                ForEach(item, id: \.id) { stat in
                    HStack {
                        VStack {
                            Image("Team/\("TBD")")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 46, height: 46)
                        }
                        .padding(.trailing, 12)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TBD")
                                .fontWeight(.semibold)
                            HStack {
                                Text("\(stat.goals)G \(stat.assists)A \(stat.points)P")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text("TBD")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 52)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding([.horizontal, .bottom])
    }
    
    var historyTab: some View {
        VStack {
            if !viewModel.stats.isEmpty {
                getHistoryStat(stat: "Recent Games", item: viewModel.stats)
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
                            Text(String(player.jerseyNumber ?? -1))
                                .font(.title3)
                                .fontWeight(.medium)
                                .frame(height: 22)
                            if let info = viewModel.info {
                                switch info.position {
                                case .goalkeeper:
                                    Text("Goalkeeper")
                                        .fontWeight(.medium)
                                case .defense:
                                    Text("Defense")
                                        .fontWeight(.medium)
                                case .forward:
                                    Text("Forward")
                                        .fontWeight(.medium)
                                case .none:
                                    Text("None")
                                        .fontWeight(.medium)
                                }
                            } else {
                                ProgressView()
                            }
                            Divider()
                                .frame(height: 22)
                            if let info = viewModel.info, let team = info.team {
                                Image("Team/\(team.code.uppercased())")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)
                                Text(team.name)
                            } else {
                                ProgressView()
                            }
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if let info = viewModel.info, let imageUrl = info.portraitURL {
                        KFImage(.init(string: imageUrl)!)
                            .placeholder {
                                ProgressView()
                                    .frame(width: 72, height: 72)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 72)
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
            .refreshable {
                try? await viewModel.refresh()
            }
        }
        .onAppear {
            Task {
                try? await viewModel.refresh()
            }
        }
    }
}

#Preview {
    PlayerView(.fakeData(), teamColor: .constant(.black))
}
