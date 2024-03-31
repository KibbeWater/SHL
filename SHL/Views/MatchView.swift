//
//  PrevMatchView.swift
//  LHF
//
//  Created by user242911 on 3/24/24.
//

import SwiftUI
import HockeyKit

private enum Tabs: String, CaseIterable {
    case summary = "Summary"
    case pbp = "Play by Play"
}

struct MatchView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    let match: Game
    @State private var pbpEvents: [PBPEventProtocol] = []
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    @State private var selectedTab: Tabs = .summary
    
    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [homeColor, awayColor]), startPoint: .leading, endPoint: .trailing)
                    
            }
            .ignoresSafeArea()
            ScrollView {
                HStack(spacing: 16) {
                    Spacer()
                    VStack {
                        Text(String(match.homeTeam.result))
                            .font(.system(size: 96))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(match.homeTeam.result > match.awayTeam.result ? .white : .white.opacity(0.5))
                            .padding(.bottom, -2)
                        Spacer()
                        Image("Team/\(match.homeTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .padding(0)
                    }
                    .frame(height: 172)
                    Spacer()
                    VStack {
                        Text(match.shootout ? "OT" : match.overtime ? "OT" : match.played ? "Full" : Calendar.current.isDate(match.date, inSameDayAs: Date()) ? FormatTime(match.date) : FormatDate(match.date))
                            .fontWeight(.semibold)
                            .font(.title)
                            .frame(height: 96)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(height: 172)
                    Spacer()
                    VStack {
                        Text(String(match.awayTeam.result))
                            .font(.system(size: 96))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(match.awayTeam.result > match.homeTeam.result ? .white : .white.opacity(0.5))
                            .padding(.bottom, -2)
                        Spacer()
                        Image("Team/\(match.awayTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .padding(0)
                    }
                    .frame(height: 172)
                    Spacer()
                }
                .padding(.bottom)
                
                HStack {
                    Spacer()
                    ForEach(Tabs.allCases, id: \.self) { tab in
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
                .padding(.top)
                
                TabView(selection: $selectedTab) {
                    Text("Summary")
                        .tag(Tabs.summary)
                        .id(Tabs.summary)
                    
                    PBPView(events: $pbpEvents)
                        .padding(.horizontal)
                        .tag(Tabs.pbp)
                        .id(Tabs.pbp)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(LinearGradient(gradient: Gradient(colors: [.clear, Color(uiColor: .systemBackground)]), startPoint: .top, endPoint: .bottom))
        }
        .onAppear {
            loadTeamColors()
        }
        .task {
            do {
                if let events = try await matchInfo.getMatchPBP(match.id) {
                    pbpEvents = events
                }
            } catch {
                print("Failed to get play-by-play events")
            }
        }
    }
    
    private func loadTeamColors() {
        let _homeColor = Color(UIImage(named: "Team/\(match.homeTeam.code)")?.getColors(quality: .low)?.background ?? UIColor.black)
        let _awayColor = Color(UIImage(named: "Team/\(match.awayTeam.code)")?.getColors(quality: .low)?.background ?? UIColor.black)
        
        withAnimation {
            self.homeColor = _homeColor
            self.awayColor = _awayColor
        }
    }
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
    }
    
    func FormatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    MatchView(match: Game.fakeData())
        .environmentObject(MatchInfo())
}
