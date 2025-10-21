import SwiftUI
import PostHog
import ActivityKit
import HockeyKit

private enum Tabs: String, CaseIterable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"
}

struct MatchListView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: Tabs = .today

    @State private var openDates: [String:Bool] = [:]

    @StateObject private var viewModel = MatchListViewModel()
    
    private func getLiveMatch(gameId: String) -> GameData.GameOverview? {
        return viewModel.matchListeners[gameId]?.gameOverview
    }
    
    var body: some View {
        VStack {
            tabSelectionView
            
            TabView(selection: $selectedTab) {
                matchesScrollView(for: viewModel.previousMatches)
                    .id(Tabs.previous)
                    .tag(Tabs.previous)
                
                matchesScrollView(for: viewModel.todayMatches)
                    .id(Tabs.today)
                    .tag(Tabs.today)
                
                matchesScrollView(for: viewModel.upcomingMatches)
                    .id(Tabs.upcoming)
                    .tag(Tabs.upcoming)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
    
    private func matchItem(_ match: Match) -> some View {
        HStack {
            if match.date < Date.now {
                NavigationLink {
                    MatchView(match, referrer: "match_list")
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
                                            PostHogSDK.shared.capture(
                                                "started_live_activity",
                                                properties: [
                                                    "join_type": "match_list_ctx"
                                                ],
                                                userProperties: [
                                                    "activity_id": ActivityUpdater.shared.deviceUUID.uuidString
                                                ]
                                            )
                                            try ActivityUpdater.shared.start(match: live)
                                        } catch {
                                            print("Failed to start activity")
                                        }
                                    }
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
                    MatchView(match, referrer: "match_list")
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
    
    private func matchesScrollView(for matches: [Match]) -> some View {
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
            try? await viewModel.refresh(hard: true)
        }
    }
}
