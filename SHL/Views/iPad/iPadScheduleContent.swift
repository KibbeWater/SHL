//
//  iPadScheduleContent.swift
//  SHL
//
//  iPad schedule content with segmented picker instead of paged TabView
//

import SwiftUI

private enum ScheduleTab: String, CaseIterable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"
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

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker with match count
            HStack {
                Picker("Schedule", selection: $selectedTab) {
                    ForEach(ScheduleTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)

                Spacer()

                Text("\(currentMatches.count) matches")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            if currentMatches.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptyIcon,
                    description: Text(emptyMessage)
                )
            } else {
                List {
                    let grouped = groupMatchesByDate(currentMatches)
                    ForEach(grouped, id: \.date) { group in
                        Section(header: Text(group.label)) {
                            ForEach(group.matches, id: \.id) { match in
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
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .contextMenu {
                                    if match.date > Date.now {
                                        #if !APPCLIP
                                        ReminderContext(game: match)
                                        #endif
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await viewModel.refresh(hard: true)
                }
            }
        }
        .refreshable {
            try? await viewModel.refresh(hard: true)
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

    private var emptyTitle: String {
        switch selectedTab {
        case .previous: return "No Previous Matches"
        case .today: return "No Games Today"
        case .upcoming: return "No Upcoming Matches"
        }
    }

    private var emptyIcon: String {
        switch selectedTab {
        case .previous: return "clock.arrow.circlepath"
        case .today: return "calendar.badge.clock"
        case .upcoming: return "calendar"
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
