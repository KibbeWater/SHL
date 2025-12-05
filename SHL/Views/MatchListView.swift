import SwiftUI
import PostHog
import ActivityKit

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
    
    private func getLiveMatch(match: Match) -> LiveMatch? {
        return viewModel.matchListeners[match.externalUUID]
    }
    
    var body: some View {
        VStack {
            tabSelectionView
            
            TabView(selection: $selectedTab) {
                matchesScrollView(for: viewModel.previousMatches, tab: .previous)
                    .id(Tabs.previous)
                    .tag(Tabs.previous)

                matchesScrollView(for: viewModel.todayMatches, tab: .today)
                    .id(Tabs.today)
                    .tag(Tabs.today)

                matchesScrollView(for: viewModel.upcomingMatches, tab: .upcoming)
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
                        MatchOverview(game: match, liveGame: getLiveMatch(match: match))
                            .id("pm-\(match.id)")
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .contextMenu {
                                #if !APPCLIP
                                Button("Start Activity", systemImage: "plus") {
                                    if let live = getLiveMatch(match: match) {
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
                        MatchOverview(game: match, liveGame: getLiveMatch(match: match))
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
    
    private func matchesScrollView(for matches: [Match], tab: Tabs) -> some View {
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
        .overlay(alignment: .center) {
            if matches.isEmpty {
                emptyStateView(for: tab)
            }
        }
        .refreshable {
            try? await viewModel.refresh(hard: true)
        }
    }

    // MARK: - Empty State

    private func emptyStateView(for tab: Tabs) -> some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon(for: tab))
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(emptyStateTitle(for: tab))
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(emptyStateMessage(for: tab))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func emptyStateIcon(for tab: Tabs) -> String {
        switch tab {
        case .previous:
            return "clock.arrow.circlepath"
        case .today:
            return "calendar.badge.clock"
        case .upcoming:
            return "calendar"
        }
    }

    private func emptyStateTitle(for tab: Tabs) -> String {
        switch tab {
        case .previous:
            return "No Previous Matches"
        case .today:
            return "No Games Today"
        case .upcoming:
            return "No Upcoming Matches"
        }
    }

    private func emptyStateMessage(for tab: Tabs) -> String {
        switch tab {
        case .previous:
            return "Past match results will appear here once games have been played."
        case .today:
            return "There are no games scheduled for today. Check the upcoming tab for future matches."
        case .upcoming:
            return "No upcoming games scheduled at the moment. Pull to refresh for updates."
        }
    }
}
