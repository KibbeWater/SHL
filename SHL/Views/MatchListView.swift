import SwiftUI
import PostHog
import ActivityKit

private enum Tabs: String, CaseIterable, Identifiable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .previous: return "clock.arrow.circlepath"
        case .today: return "calendar.badge.clock"
        case .upcoming: return "calendar"
        }
    }
}

struct MatchListView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: Tabs = .today
    @State private var openDates: [String: Bool] = [:]
    @State private var refreshTick = 0

    @StateObject private var viewModel = MatchListViewModel()

    private func getLiveMatch(match: Match) -> LiveMatch? {
        return viewModel.matchListeners[match.externalUUID]
    }

    var body: some View {
        VStack(spacing: 0) {
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
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await viewModel.refresh(hard: true)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.success, trigger: refreshTick)
    }

    // MARK: - Tab selector (native segmented control)

    private var tabSelectionView: some View {
        Picker("Filter", selection: $selectedTab) {
            ForEach(Tabs.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
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
                            .contextMenu {
                                #if !APPCLIP
                                Button("Start Activity", systemImage: "plus") {
                                    if let live = getLiveMatch(match: match) {
                                        do {
                                            PostHogSDK.shared.capture(
                                                "started_live_activity",
                                                properties: ["join_type": "match_list_ctx"],
                                                userProperties: ["activity_id": KeychainManager.shared.getDeviceId()]
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
                            .padding(.horizontal)
                    }
                }
                .buttonStyle(.scalePress)
            } else {
                NavigationLink {
                    MatchView(match, referrer: "match_list")
                } label: {
                    MatchOverview(game: match, liveGame: getLiveMatch(match: match))
                        .id("pm-\(match.id)")
                        .contextMenu {
                            ReminderContext(game: match)
                        }
                        .padding(.horizontal)
                }
                .buttonStyle(.scalePress)
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
                        let isOpen = openDates[key] == true || isFirst

                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Text(getGroupDate(matchList.first?.date ?? Date.now))
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .kerning(0.5)
                                Spacer()
                                if !isFirst {
                                    Button {
                                        withAnimation(.snappy) {
                                            openDates[key] = !isOpen
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(isOpen ? "Show less" : "Show more")
                                            Image(systemName: "chevron.down")
                                                .rotationEffect(.degrees(isOpen ? 180 : 0))
                                                .animation(.snappy, value: isOpen)
                                        }
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.tint)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)

                            if isOpen {
                                LazyVStack(spacing: 10) {
                                    ForEach(matchList, id: \.id) { match in
                                        matchItem(match)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.bottom, 12)
                    }
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(matches, id: \.id) { match in
                            matchItem(match)
                        }
                    }
                    .padding(.top, 8)
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
            refreshTick &+= 1
        }
    }

    // MARK: - Empty State

    private func emptyStateView(for tab: Tabs) -> some View {
        ContentUnavailableView {
            Label(emptyStateTitle(for: tab), systemImage: tab.systemImage)
        } description: {
            Text(emptyStateMessage(for: tab))
        }
    }

    private func emptyStateTitle(for tab: Tabs) -> String {
        switch tab {
        case .previous: return "No Previous Matches"
        case .today: return "No Games Today"
        case .upcoming: return "No Upcoming Matches"
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

#Preview {
    NavigationStack { MatchListView() }
}

#Preview("Dark") {
    NavigationStack { MatchListView() }
        .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    NavigationStack { MatchListView() }
}
