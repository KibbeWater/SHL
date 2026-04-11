//
//  iPadScheduleContent.swift
//  SHL
//
//  iPad schedule content with live game highlights and compact match cards
//

import SwiftUI

private enum ScheduleTab: String, CaseIterable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"

    var icon: String {
        switch self {
        case .previous: return "clock.arrow.circlepath"
        case .today: return "calendar.badge.clock"
        case .upcoming: return "calendar"
        }
    }
}

struct iPadScheduleContent: View {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var viewModel: MatchListViewModel
    var onSelectMatch: (Match) -> Void

    @State private var selectedTab: ScheduleTab = .today

    private var currentMatches: [Match] {
        switch selectedTab {
        case .previous: return viewModel.previousMatches
        case .today: return viewModel.todayMatches
        case .upcoming: return viewModel.upcomingMatches
        }
    }

    private func getLiveMatch(for match: Match) -> LiveMatch? {
        viewModel.matchListeners[match.externalUUID]
    }

    // Live or in-progress games for the "today" tab
    private var liveMatches: [Match] {
        viewModel.todayMatches.filter { match in
            if let live = getLiveMatch(for: match) {
                return live.gameState == .ongoing || live.gameState == .paused
            }
            return match.isLive()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with picker
            headerBar

            Divider().opacity(0.3)

            if currentMatches.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Live Now section (only on Today tab)
                        if selectedTab == .today && !liveMatches.isEmpty {
                            liveNowSection
                        }

                        // Grouped match list
                        let groups = groupMatchesByDate(currentMatches)
                        ForEach(groups, id: \.date) { group in
                            dateSection(group)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .refreshable {
                    try? await viewModel.refresh(hard: true)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await viewModel.refresh(hard: true)
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 8) {
            Picker("Schedule", selection: $selectedTab) {
                ForEach(ScheduleTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Live Now

    private var liveNowSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Live Now")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            VStack(spacing: 8) {
                ForEach(liveMatches) { match in
                    Button {
                        onSelectMatch(match)
                    } label: {
                        MatchOverview(
                            game: match,
                            liveGame: getLiveMatch(for: match)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Date Section

    private func dateSection(_ group: MatchGroup) -> some View {
        VStack(spacing: 0) {
            // Date header
            HStack(alignment: .firstTextBaseline) {
                Text(group.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(group.matches.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)

            // Match cards
            VStack(spacing: 6) {
                ForEach(group.matches, id: \.id) { match in
                    Button {
                        onSelectMatch(match)
                    } label: {
                        MatchCardCompact(
                            game: match,
                            liveGame: getLiveMatch(for: match)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if match.date > Date.now {
                            #if !APPCLIP
                            ReminderContext(game: match)
                            #endif
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Grouping

    private struct MatchGroup {
        let date: Date
        let label: String
        let matches: [Match]
    }

    private func groupMatchesByDate(_ matches: [Match]) -> [MatchGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        var groups: [Date: [Match]] = [:]
        for match in matches {
            let day = calendar.startOfDay(for: match.date)
            groups[day, default: []].append(match)
        }

        return groups.keys.sorted().map { day in
            let matches = groups[day]!
            let sameYear = calendar.isDate(day, equalTo: Date.now, toGranularity: .year)
            formatter.dateFormat = sameYear ? "EEEE, d MMM" : "EEEE, d MMM yyyy"
            return MatchGroup(date: day, label: formatter.string(from: day), matches: matches)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: selectedTab.icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(emptyTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyTitle: String {
        switch selectedTab {
        case .previous: return "No Previous Matches"
        case .today: return "No Games Today"
        case .upcoming: return "No Upcoming Matches"
        }
    }

    private var emptyMessage: String {
        switch selectedTab {
        case .previous: return "Past match results will appear here once games have been played."
        case .today: return "There are no games scheduled for today. Check the upcoming tab for future matches."
        case .upcoming: return "No upcoming games scheduled at the moment. Pull to refresh for updates."
        }
    }
}
