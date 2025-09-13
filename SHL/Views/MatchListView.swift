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
    @Environment(\.hockeyAPI) private var api: HockeyAPI
    
    @State private var selectedTab: Tabs = .today
    
    @State private var openDates: [String:Bool] = [:]

    @StateObject private var viewModel = MatchListViewModel()
    
    @Namespace var animation
    @State private var selectedMatch: Game?
    
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
        .task {
            viewModel.setAPI(api)
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
    
    @available(iOS 18.0, *)
    private func matchItem(_ match: Game) -> some View {
        HStack {
            if match.date < Date.now {
                Button {
                    selectedMatch = match
                } label: {
                    MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                        .id("pm-\(match.id)")
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        .contextMenu {
                            if let live = getLiveMatch(gameId: match.id) {
                                LiveContext(live: live)
                            }
                        }
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
                .matchedTransitionSource(id: match.id, in: animation)
            } else {
                Button {
                    selectedMatch = match
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
                .matchedTransitionSource(id: match.id, in: animation)
            }
        }
        .sheet(item: $selectedMatch) { match in
            MatchView(match, referrer: "match_list", animation: animation)
                .navigationTransition(.zoom(sourceID: match.id, in: animation))
                .presentationDragIndicator(.visible)
        }
    }
    
    @available(iOS 17.0, *)
    private func matchItem17(_ match: Game) -> some View {
        HStack {
            if match.date < Date.now {
                Button {
                    selectedMatch = match
                } label: {
                    MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                        .id("pm-\(match.id)")
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        .contextMenu {
                            if let live = getLiveMatch(gameId: match.id) {
                                LiveContext(live: live)
                            }
                        }
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button {
                    selectedMatch = match
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
        .sheet(item: $selectedMatch) { match in
            MatchView(match, referrer: "match_list", animation: animation)
                .presentationDragIndicator(.visible)
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
                            VStack {
                                ForEach(matchList, id: \.id) { match in
                                    if #available(iOS 18.0, *) {
                                        matchItem(match)
                                    } else {
                                        matchItem17(match)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                }
            } else {
                ForEach(matches, id: \.id) { match in
                    if #available(iOS 18.0, *) {
                        matchItem(match)
                    } else {
                        matchItem17(match)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .center, content: {
            if (matches.isEmpty) {
                Text("No matches")
            }
        })
        .refreshable {
            try? await viewModel.refresh()
        }
    }
}

#Preview("Preview") {
    MatchListView()
        .environment(\.hockeyAPI, HockeyAPI())
}
