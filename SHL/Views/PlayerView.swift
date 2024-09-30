//
//  PlayerView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/9/24.
//

import SwiftUI
import HockeyKit

struct PlayerView: View {
    let player: LineupPlayer
    @Binding var teamColor: Color
    
    @State private var playerInfo: Player? = nil

    func loadPlayerInfo() async {
        self.playerInfo = try? await PlayerAPI.shared.getPlayer(id: player.uuid)
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
