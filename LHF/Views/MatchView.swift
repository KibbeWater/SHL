import SwiftUI
import HockeyKit

enum Tabs: String, CaseIterable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"
}

struct MatchView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    @State private var selectedTab: Tabs = .today
    @State private var previousMatches: [Game] = []
    @State private var todayMatches: [Game] = []
    @State private var upcomingMatches: [Game] = []

    // When matchInfo changes, re-filter the matches
    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current
        previousMatches = matchInfo.latestMatches.filter { $0.date < calendar.startOfDay(for: now) }
        todayMatches = matchInfo.latestMatches.filter { calendar.isDateInToday($0.date) }
        upcomingMatches = matchInfo.latestMatches.filter { calendar.startOfDay(for: $0.date) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }
    }
    
    var body: some View {
        VStack {
            tabSelectionView

            TabView(selection: $selectedTab) {
                matchesScrollView(for: previousMatches)
                    .id(Tabs.previous)
                    .tag(Tabs.previous)
                
                matchesScrollView(for: todayMatches)
                    .id(Tabs.today)
                    .tag(Tabs.today)
                
                matchesScrollView(for: upcomingMatches)
                    .id(Tabs.upcoming)
                    .tag(Tabs.upcoming)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
        .onAppear {
            filterMatches()
        }
    }
    
    private var tabSelectionView: some View {
        HStack {
            Spacer()
            ForEach(Tabs.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }, label: {
                    Text(tab.rawValue)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                })
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
    }
    
    private func matchesScrollView(for matches: [Game]) -> some View {
        ScrollView {
            ForEach(matches, id: \.id) { match in
                PrevMatch(game: match)
                    .id("pm-\(match.id)")
            }
        }
        .padding(.horizontal)
    }
}
