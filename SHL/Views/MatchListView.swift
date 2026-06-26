//
//  MatchListView.swift
//  SHL
//
//  The redesigned Schedule — a date-navigated calendar rather than a flat dump of
//  the whole season. A week strip (with dots on days that have games) drives the
//  view; only the visible week is loaded. Filter by team, jump to any date, and
//  see the selected day's games — with a bold Live Now highlight when today is in
//  view. Adaptive for iPhone + iPad.
//

import SwiftUI

struct MatchListView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: ScheduleViewModel
    @State private var showDatePicker = false

    @MainActor
    init(viewModel: ScheduleViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? ScheduleViewModel())
    }

    private var favoriteCode: String? { Settings.shared.getFavoriteTeam()?.code }

    var body: some View {
        ZStack {
            RinkAmbientBackground(.arena)
            VStack(spacing: 0) {
                weekStrip
                Divider().opacity(0.15)
                dayContent
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { toolbar }
        .task { await viewModel.loadInitial() }
        .onDisappear { viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.loadWeek(force: true) } }
        }
        .sheet(isPresented: $showDatePicker) { datePickerSheet }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Today") { withAnimation(.snappy) { viewModel.goToToday() } }
                .tint(Rink.ice)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showDatePicker = true } label: { Image(systemName: "calendar") }
                .tint(Rink.ice)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Team", selection: teamBinding) {
                    Text("All Teams").tag(String?.none)
                    ForEach(viewModel.teams) { team in
                        Text(team.name).tag(Optional(team.code))
                    }
                }
            } label: {
                Image(systemName: viewModel.teamFilter == nil
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
            }
            .tint(Rink.ice)
        }
    }

    private var teamBinding: Binding<String?> {
        Binding(get: { viewModel.teamFilter }, set: { viewModel.setTeamFilter($0) })
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        VStack(spacing: 10) {
            HStack {
                Button { withAnimation(.snappy) { viewModel.changeWeek(by: -1) } } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(viewModel.monthYearLabel).font(.subheadline.weight(.semibold))
                Spacer()
                Button { withAnimation(.snappy) { viewModel.changeWeek(by: 1) } } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.subheadline.weight(.semibold))
            .tint(Rink.ice)

            HStack(spacing: 6) {
                ForEach(viewModel.weekDays, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    private func dayCell(_ day: Date) -> some View {
        let selected = viewModel.isSelected(day)
        let today = viewModel.isToday(day)
        let hasGames = viewModel.hasGames(on: day)
        return Button {
            withAnimation(.snappy) { viewModel.select(day) }
        } label: {
            VStack(spacing: 4) {
                Text(Self.weekdayFmt.string(from: day).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                Text(Self.dayFmt.string(from: day))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                Circle()
                    .fill(hasGames ? (selected ? Color.white : Rink.ice) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Rink.ice) : AnyShapeStyle(Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(today && !selected ? Rink.ice.opacity(0.5) : .clear, lineWidth: 1.5)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day content

    private var dayContent: some View {
        ScrollView {
            let games = viewModel.selectedGames
            let live = viewModel.liveSelectedGames
            let rest = games.filter { g in !live.contains(where: { $0.id == g.id }) }

            LazyVStack(alignment: .leading, spacing: .RinkSpace.lg) {
                dayHeader(count: games.count)

                if games.isEmpty {
                    emptyState
                } else {
                    if !live.isEmpty { liveNowSection(live) }
                    if !rest.isEmpty {
                        VStack(spacing: .RinkSpace.sm) {
                            ForEach(rest, id: \.id) { match in
                                rowLink(match)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, .RinkSpace.md)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .refreshable { await viewModel.loadWeek(force: true) }
    }

    private func dayHeader(count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(fullDateLabel(viewModel.selectedDate))
                .font(.title3.weight(.bold))
            Spacer()
            if count > 0 {
                Text("\(count) \(count == 1 ? "game" : "games")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func liveNowSection(_ live: [Match]) -> some View {
        VStack(alignment: .leading, spacing: .RinkSpace.md) {
            RinkSectionHeader("Live Now",
                              subtitle: live.count == 1 ? "1 game in progress" : "\(live.count) games in progress",
                              icon: "dot.radiowaves.left.and.right",
                              iconTint: Rink.goal)
            if live.count == 1 {
                liveCard(live[0])
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: .RinkSpace.md)],
                          spacing: .RinkSpace.md) {
                    ForEach(live, id: \.id) { liveCard($0) }
                }
            }
        }
    }

    private func liveCard(_ match: Match) -> some View {
        NavigationLink {
            MatchView(match, referrer: "schedule_live")
        } label: {
            LiveGameCard(match: match, live: viewModel.live(for: match))
        }
        .buttonStyle(.plain)
    }

    private func rowLink(_ match: Match) -> some View {
        NavigationLink {
            MatchView(match, referrer: "schedule")
        } label: {
            ScheduleMatchRow(match: match, live: viewModel.live(for: match), favoriteCode: favoriteCode)
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

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Games", systemImage: "calendar")
        } description: {
            Text("There are no games on \(fullDateLabel(viewModel.selectedDate)). Try another day — dots mark days with games.")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Jump to date

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("Jump to date",
                       selection: Binding(get: { viewModel.selectedDate },
                                          set: { viewModel.select($0); showDatePicker = false }),
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Rink.ice)
                .padding()
                .navigationTitle("Jump to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDatePicker = false }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Date formatting

    private func fullDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return String(localized: "Today") }
        if cal.isDateInTomorrow(date) { return String(localized: "Tomorrow") }
        if cal.isDateInYesterday(date) { return String(localized: "Yesterday") }
        return Self.fullDateFmt.string(from: date)
    }

    private static let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("EEE"); return f
    }()
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "d"; return f
    }()
    private static let fullDateFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("EEEEdMMMM"); return f
    }()
}

#Preview {
    NavigationStack { MatchListView(viewModel: .preview()) }
}

#Preview("Dark") {
    NavigationStack { MatchListView(viewModel: .preview()) }
        .preferredColorScheme(.dark)
}
