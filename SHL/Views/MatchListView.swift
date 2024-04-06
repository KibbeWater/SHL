import SwiftUI
import ActivityKit
import HockeyKit

private enum Tabs: String, CaseIterable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"
}

struct MatchListView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    @State private var selectedTab: Tabs = .today
    @State private var previousMatches: [Game] = []
    @State private var todayMatches: [Game] = []
    @State private var upcomingMatches: [Game] = []
    
    @State private var matchListeners: [GameUpdater] = []

    // When matchInfo changes, re-filter the matches
    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current
        previousMatches = matchInfo.latestMatches.filter { $0.date < calendar.startOfDay(for: now) }
        todayMatches = matchInfo.latestMatches.filter { calendar.isDateInToday($0.date) }
        upcomingMatches = matchInfo.latestMatches.filter { calendar.startOfDay(for: $0.date) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }
        
        matchListeners.removeAll(where: { _listener in
            return !todayMatches.contains(where: { $0.id == _listener.gameId })
        })
        let missingListeners = todayMatches.filter({ _match in
            return !matchListeners.contains(where: { $0.gameId == _match.id })
        })
        
        matchListeners.append(contentsOf: missingListeners.map({ _match in
            return GameUpdater(gameId: _match.id)
        }))
    }
    
    private func getLiveMatch(gameId: String) -> GameOverview? {
        return matchListeners.first(where: { $0.gameId == gameId })?.game
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
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear {
            self.filterMatches()
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
    
    private func refresh() async {
        matchListeners.forEach({ $0.refreshPoller() })
        do {
            try await matchInfo.getLatest()
        } catch {
            print("Unable to refresh matches")
        }
    }
    
    private func matchesScrollView(for matches: [Game]) -> some View {
        VStack {
            ScrollView {
                ForEach(matches, id: \.id) { match in
                    if match.date < Date.now {
                        NavigationLink {
                            MatchView(match: match)
                        } label: {
                            MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                                .id("pm-\(match.id)")
                                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                                .contextMenu {
                                    let activityActive = Activity<SHLWidgetAttributes>.activities.contains(where: { $0.attributes.id == match.id })
                                    Button(activityActive ? "Stop Activity" : "Start Activity", systemImage: activityActive ? "minus" : "plus") {
                                        if let live = getLiveMatch(gameId: match.id) {
                                            if activityActive {
                                                do {
                                                    try ActivityUpdater.shared.start(match: live)
                                                } catch {
                                                    print("Failed to start activity")
                                                }
                                            } else {
                                                let activity = Activity<SHLWidgetAttributes>.activities.first(where: { $0.attributes.id == match.id })
                                                Task {
                                                    await activity?.end(nil, dismissalPolicy: .immediate)
                                                }
                                            }
                                        }
                                    }
                                    
                                    Button("Debug Activity", systemImage: "plus") {
                                        Task {
                                            if let _match = try await matchInfo.getMatch(match.id) {
                                                do {
                                                    try ActivityUpdater.shared.start(match: _match)
                                                } catch {
                                                    print("Failed to start activity")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        MatchOverview(game: match)
                            .id("pm-\(match.id)")
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .padding(.horizontal)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .center, content: {
            if (matches.isEmpty) {
                Text("No matches")
            }
        })
        .refreshable {
            await refresh()
        }
    }
}
