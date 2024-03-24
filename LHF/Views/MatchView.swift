//
//  MatchView.swift
//  LHF
//
//  Created by KibbeWater on 3/23/24.
//

import SwiftUI
import HockeyKit

enum Tabs: String, CaseIterable  {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"
}

struct MatchView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    @State var selectedTab: Tabs = .today
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(Tabs.allCases, id: \.rawValue) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }, label: {
                    Text(String(tab.rawValue))
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                })
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
        
        TabView(selection: $selectedTab) {
            ScrollView {
                ForEach(matchInfo.latestMatches.filter({$0.date<Calendar.current.startOfDay(for: Date())})) { match in
                    PrevMatch(game: match)
                }
            }
            .padding(.horizontal)
            .tag(Tabs.previous)
            
            ScrollView {
                ForEach(matchInfo.latestMatches.filter({Calendar.current.isDateInToday($0.date)})) { match in
                    PrevMatch(game: match)
                }
            }
            .padding(.horizontal)
            .tag(Tabs.today)
            
            ScrollView {
                ForEach(matchInfo.latestMatches.filter { Calendar.current.startOfDay(for: $0.date) >= Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! }) { match in
                    PrevMatch(game: match)
                }
            }
            .padding(.horizontal)
            .tag(Tabs.upcoming)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    MatchView()
        .environmentObject(MatchInfo())
}
