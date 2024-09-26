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
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab: Tabs = .today
    @State private var latestMatches: SeasonSchedule? = nil
    @State private var previousMatches: [Game] = []
    @State private var todayMatches: [Game] = []
    @State private var upcomingMatches: [Game] = []
    
    @State private var matchListeners: [GameUpdater] = []
    
    @State private var openDates: [String: Bool] = [:]

    // When matchInfo changes, re-filter the matches
    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current
        previousMatches = latestMatches?.gameInfo.filter({ $0.startDateTime < calendar.startOfDay(for: now) }).map { $0.toGame() } ?? []
        todayMatches = latestMatches?.gameInfo.filter({ calendar.isDateInToday($0.startDateTime) }).map { $0.toGame() } ?? []
        upcomingMatches = latestMatches?.gameInfo.filter({ calendar.startOfDay(for: $0.startDateTime) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }).map { $0.toGame() } ?? []
        
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
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
        .onAppear {
            Task {
                print("Fetching season")
                if let season = try? await matchInfo.getCurrentSeason() {
                    print("Current season found")
                    print(season)
                    latestMatches = try? await matchInfo.getSchedule(season)
                }
            }
        }
        .onChange(of: latestMatches) { _ in
            filterMatches()
        }
        .onChange(of: scenePhase) { _ in
            guard scenePhase == .active else {
                return
            }
            
            matchListeners.forEach { listener in
                listener.refreshPoller()
            }
            
            Task {
                do {
                    try await matchInfo.getLatest()
                } catch {
                    print("Unable to refresh")
                }
            }
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
    
    private func matchItem(_ match: Game) -> some View {
        HStack {
            if match.date < Date.now {
                NavigationLink {
                    MatchView(match: match)
                } label: {
                    if #available(iOS 17.2, *) {
                        MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                            .id("pm-\(match.id)")
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .contextMenu {
                                #if !APPCLIP
                                Button("Start Activity", systemImage: "plus") {
                                    if let live = getLiveMatch(gameId: match.id) {
                                        do {
                                            try ActivityUpdater.shared.start(match: live)
                                        } catch {
                                            print("Failed to start activity")
                                        }
                                    }
                                }
                                #endif
                                
                                #if DEBUG
                                Button("Debug Activity") {
                                    try? ActivityUpdater.shared.start(match: GameOverview.generateFake())
                                }
                                #endif
                            }
                            .padding(.horizontal)
                    } else {
                        MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                            .id("pm-\(match.id)")
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .padding(.horizontal)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                NavigationLink {
                    MatchView(match: match)
                } label: {
                    MatchOverview(game: match)
                        .id("pm-\(match.id)")
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        .contextMenu {
                            ReminderContext(game: match)
                        }
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func getDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    private func getGroupDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Calendar.current.isDate(Date.now, equalTo: date, toGranularity: .year) 
            ? "EEEE, d MMM"
            : "EEEE, d MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    private func matchesScrollView(for matches: [Game]) -> some View {
        VStack {
            ScrollView {
                if matches.first?.date ?? Date.now > Date.now {
                    let matchGroups = matches.groupBy(keySelector: { getDate($0.date) })
                    ForEach(matchGroups.keys.sorted(), id: \.self) { key in
                        let matchList = matchGroups[key]!
                        let isFirst = matchGroups.keys.sorted().first == key
                        VStack {
                            HStack {
                                Text(getGroupDate(matchList.first?.date ?? Date.now))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.bold)
                                Spacer()
                                if !isFirst {
                                    Button(openDates[key] == true ? "Show less" : "Show more", systemImage: openDates[key] == true ? "chevron.up" : "chevron.down") {
                                        let isOpen = openDates[key] ?? false
                                        withAnimation {
                                            if isOpen {
                                                openDates[key] = false
                                            } else {
                                                openDates[key] = true
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            if openDates[key] == true || isFirst {
                                LazyVStack {
                                    ForEach(matchList, id: \.id) { match in
                                        matchItem(match)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                } else {
                    ForEach(matches, id: \.id) { match in
                        matchItem(match)
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
