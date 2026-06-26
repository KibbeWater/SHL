//
//  HomeView.swift
//  SHL
//
//  The redesigned home — a personalized, sectioned feed driven by the single v2
//  `HomeSummary`. It leads with the user's favorite team, then the featured
//  matchup, a live rail, upcoming + recent games, a standings snapshot, and the
//  league leaders. Adaptive: a single column on iPhone, a multi-column dashboard
//  on iPad. Built entirely on the Rink design system.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: HomeFeedViewModel
    @State private var gamesTab: Int = 0
    @State private var favoriteGlow: Color? = nil
    @State private var championGlow: Color? = nil

    @MainActor
    init(viewModel: HomeFeedViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? HomeFeedViewModel())
    }

    private var favoriteId: String? { Settings.shared.getFavoriteTeamId() }

    var body: some View {
        ZStack {
            RinkAmbientBackground(ambientTheme)
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            if viewModel.summary == nil { await viewModel.load() }
            resolveGlows()
        }
        .onChange(of: viewModel.summary?.favorite?.team.code) { _, _ in resolveGlows() }
        .onChange(of: viewModel.summary?.champion?.team.code) { _, _ in resolveGlows() }
        .onDisappear { viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.refresh() } }
        }
    }

    /// Phase-aware backdrop: aurora during the build-up to a new season, the
    /// champion's colors over a concluded season, the favorite's tint (or cool
    /// arena) in-season.
    private var ambientTheme: RinkAmbientBackground.Theme {
        switch viewModel.phase {
        case .preseason: return .aurora
        case .concluded: return championGlow.map { .team($0) } ?? .arena
        case .regular:   return favoriteGlow.map { .team($0) } ?? .arena
        }
    }

    private func resolveGlows() {
        if let code = viewModel.summary?.favorite?.team.code {
            getCodeColor(teamKey: "Team/\(code.uppercased())") { favoriteGlow = $0 }
        }
        if let code = viewModel.summary?.champion?.team.code {
            getCodeColor(teamKey: "Team/\(code.uppercased())") { championGlow = $0 }
        }
    }

    // MARK: - Top-level state

    @ViewBuilder
    private var content: some View {
        if let summary = viewModel.summary {
            ScrollView {
                Group {
                    switch summary.phase {
                    case .preseason:
                        preseasonLayout(summary)
                    case .concluded:
                        concludedLayout(summary)
                    case .regular:
                        if hSizeClass == .regular {
                            regularLayout(summary)
                        } else {
                            compactLayout(summary)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        } else if viewModel.isLoading {
            ProgressView().controlSize(.large)
        } else {
            HomeUnavailableView { Task { await viewModel.load() } }
        }
    }

    // MARK: - Layouts

    private func compactLayout(_ summary: HomeSummary) -> some View {
        VStack(spacing: .RinkSpace.section) {
            HomeGreetingHeader()

            if let fav = summary.favorite {
                FavoriteSpotlightCard(favorite: fav, team: viewModel.favoriteTeam)
            }
            if let featured = summary.featured {
                featuredHero(featured)
            }
            if !viewModel.secondaryLiveGames.isEmpty {
                liveRail
            }
            if !summary.upcoming.isEmpty || !summary.recent.isEmpty {
                gamesSection(summary)
            }
            if !viewModel.standings.isEmpty {
                standingsSection
            }
            if let leaders = summary.leaders, !leaders.boards.isEmpty {
                leadersSection(leaders)
            }
        }
        .padding(.horizontal)
        .padding(.top, .RinkSpace.sm)
        .padding(.bottom, 32)
    }

    private func regularLayout(_ summary: HomeSummary) -> some View {
        VStack(spacing: .RinkSpace.section) {
            HomeGreetingHeader()
                .frame(maxWidth: .infinity, alignment: .leading)

            // Hero row — favorite + featured side by side.
            topRow(summary)

            if !viewModel.secondaryLiveGames.isEmpty {
                liveRail
            }

            // Two columns: games on the left, standings on the right.
            HStack(alignment: .top, spacing: .RinkSpace.xl) {
                VStack(spacing: .RinkSpace.section) {
                    if !summary.upcoming.isEmpty || !summary.recent.isEmpty {
                        gamesSection(summary)
                    }
                }
                .frame(maxWidth: .infinity)

                if !viewModel.standings.isEmpty {
                    standingsSection.frame(maxWidth: .infinity)
                }
            }

            if let leaders = summary.leaders, !leaders.boards.isEmpty {
                leadersSection(leaders)
            }
        }
        .padding(.horizontal, .RinkSpace.xl)
        .padding(.vertical, .RinkSpace.lg)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func topRow(_ summary: HomeSummary) -> some View {
        if let fav = summary.favorite, let featured = summary.featured {
            HStack(alignment: .top, spacing: .RinkSpace.xl) {
                FavoriteSpotlightCard(favorite: fav, team: viewModel.favoriteTeam)
                    .frame(maxWidth: .infinity)
                featuredHero(featured)
                    .frame(maxWidth: .infinity)
            }
        } else if let fav = summary.favorite {
            FavoriteSpotlightCard(favorite: fav, team: viewModel.favoriteTeam)
        } else if let featured = summary.featured {
            featuredHero(featured)
        }
    }

    // MARK: - Pre-season variant

    /// The opener date: the season's official start, else the first scheduled game.
    private func openingDate(_ summary: HomeSummary) -> Date? {
        summary.season?.startDate ?? summary.upcoming.first?.date ?? summary.favorite?.nextMatch?.date
    }

    /// Anticipation home: a countdown to opening night, the user's opener, the
    /// opening fixtures, and a recap of last season's final table.
    private func preseasonLayout(_ summary: HomeSummary) -> some View {
        VStack(spacing: .RinkSpace.section) {
            HomeGreetingHeader()

            if let opening = openingDate(summary) {
                PreseasonHeroCard(openingDate: opening,
                                  seasonName: summary.season?.name ?? summary.season?.code)
            }

            // The user's first game (or the league opener when there's no favorite).
            if let opener = summary.favorite?.nextMatch ?? summary.featured {
                VStack(alignment: .leading, spacing: .RinkSpace.md) {
                    RinkSectionHeader(summary.favorite != nil ? "Your Opener" : "Opening Game",
                                      icon: "flag.checkered")
                    matchLink(opener, referrer: "home_preseason_opener") {
                        FeaturedHeroCard(match: opener, live: nil)
                    }
                }
            }

            if !summary.upcoming.isEmpty {
                VStack(alignment: .leading, spacing: .RinkSpace.md) {
                    RinkSectionHeader("Opening Fixtures", icon: "calendar") {
                        seeAll { MatchListView() }
                    }
                    VStack(spacing: .RinkSpace.sm) {
                        ForEach(summary.upcoming.prefix(6), id: \.id) { match in
                            matchLink(match, referrer: "home_preseason_fixtures") {
                                MatchCardCompact(game: match, liveGame: nil)
                            }
                        }
                    }
                }
            }

            if !viewModel.previousStandings.isEmpty {
                VStack(alignment: .leading, spacing: .RinkSpace.md) {
                    RinkSectionHeader("Last Season", subtitle: "Final standings",
                                      icon: "clock.arrow.circlepath")
                    RinkCard(.plain, padding: 0) {
                        StandingsTable(
                            title: "",
                            items: Array(viewModel.previousStandings.prefix(8)),
                            favoriteTeamId: favoriteId,
                            showsHeader: false
                        )
                        .padding(.vertical, .RinkSpace.sm)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, .RinkSpace.sm)
        .padding(.bottom, 32)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Concluded variant

    /// Wrap-up home: crowns the champion, recaps the user's season, and shows the
    /// final table + season-total leaders.
    private func concludedLayout(_ summary: HomeSummary) -> some View {
        VStack(spacing: .RinkSpace.section) {
            HomeGreetingHeader()

            if let champ = summary.champion {
                ChampionHeroCard(champion: champ,
                                 seasonName: summary.season?.name ?? summary.season?.code)
            }

            if let fav = summary.favorite {
                VStack(alignment: .leading, spacing: .RinkSpace.md) {
                    RinkSectionHeader("Your Season", icon: "star.fill", iconTint: Rink.gold)
                    FavoriteSpotlightCard(favorite: fav, team: viewModel.favoriteTeam)
                }
            }

            if !viewModel.standings.isEmpty {
                VStack(alignment: .leading, spacing: .RinkSpace.md) {
                    RinkSectionHeader("Final Standings", icon: "list.number") {
                        seeAll { AllStandingsView(items: viewModel.standings, favoriteId: favoriteId) }
                    }
                    RinkCard(.plain, padding: 0) {
                        StandingsTable(
                            title: "",
                            items: viewModel.standingsSnapshot(favoriteId: favoriteId),
                            favoriteTeamId: favoriteId,
                            showsHeader: false
                        )
                        .padding(.vertical, .RinkSpace.sm)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }

            if let leaders = summary.leaders, !leaders.boards.isEmpty {
                leadersSection(leaders)
            }

            SeasonClosedNote()
        }
        .padding(.horizontal)
        .padding(.top, .RinkSpace.sm)
        .padding(.bottom, 32)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sections

    private func featuredHero(_ featured: Match) -> some View {
        matchLink(featured, referrer: "home_featured") {
            FeaturedHeroCard(match: featured, live: viewModel.live(for: featured))
        }
    }

    /// "Live Now" reflows by count: one game fills the width, several lay out in
    /// an adaptive grid (two-up on iPhone, more on iPad). No horizontal scroll,
    /// so nothing clips at the edges.
    private var liveRail: some View {
        let games = viewModel.secondaryLiveGames
        return VStack(alignment: .leading, spacing: .RinkSpace.md) {
            RinkSectionHeader("Live Now",
                              subtitle: liveSubtitle,
                              icon: "dot.radiowaves.left.and.right",
                              iconTint: Rink.goal)
            if games.count == 1 {
                liveCard(games[0])
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: .RinkSpace.md)],
                          spacing: .RinkSpace.md) {
                    ForEach(games, id: \.id) { liveCard($0) }
                }
            }
        }
    }

    private var liveSubtitle: String {
        let n = viewModel.liveGames.count
        return n == 1 ? "1 game in progress" : "\(n) games in progress"
    }

    private func liveCard(_ game: Match) -> some View {
        matchLink(game, referrer: "home_live") {
            LiveGameCard(match: game, live: viewModel.live(for: game))
        }
    }

    /// Upcoming + Results consolidated into one card with a segmented toggle —
    /// half the vertical footprint of two separate lists.
    private func gamesSection(_ summary: HomeSummary) -> some View {
        let matches = (gamesTab == 0 ? summary.upcoming : summary.recent)
        return VStack(alignment: .leading, spacing: .RinkSpace.md) {
            RinkSectionHeader("Games", icon: "sportscourt.fill") {
                seeAll { MatchListView() }
            }
            VStack(spacing: .RinkSpace.md) {
                Picker("", selection: $gamesTab) {
                    Text("Upcoming").tag(0)
                    Text("Results").tag(1)
                }
                .pickerStyle(.segmented)

                if matches.isEmpty {
                    Text(gamesTab == 0 ? "No upcoming games" : "No recent results")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .RinkSpace.lg)
                } else {
                    VStack(spacing: .RinkSpace.sm) {
                        ForEach(matches.prefix(4), id: \.id) { match in
                            matchLink(match, referrer: gamesTab == 0 ? "home_upcoming" : "home_recent") {
                                MatchCardCompact(game: match, liveGame: viewModel.live(for: match))
                            }
                        }
                    }
                }
            }
        }
    }

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: .RinkSpace.md) {
            RinkSectionHeader("Standings", icon: "list.number") {
                seeAll { AllStandingsView(items: viewModel.standings, favoriteId: favoriteId) }
            }
            RinkCard(.plain, padding: 0) {
                StandingsTable(
                    title: "",
                    items: viewModel.standingsSnapshot(favoriteId: favoriteId),
                    favoriteTeamId: favoriteId,
                    showsHeader: false
                )
                .padding(.vertical, .RinkSpace.sm)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    /// Leaders as a peeking carousel — the next board's edge shows, so it reads as
    /// scrollable, and it stays one row tall instead of three stacked cards.
    private func leadersSection(_ leaders: LeagueLeaders) -> some View {
        VStack(alignment: .leading, spacing: .RinkSpace.md) {
            RinkSectionHeader("League Leaders", icon: "trophy.fill", iconTint: Rink.gold)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .RinkSpace.md) {
                    ForEach(leaders.boards) { board in
                        LeaderBoardCard(board: board)
                            .frame(width: 260)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func matchLink<Label: View>(_ match: Match, referrer: String,
                                        @ViewBuilder label: () -> Label) -> some View {
        NavigationLink {
            MatchView(match, referrer: referrer)
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }

    private func seeAll<D: View>(@ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 2) {
                Text("See All")
                Image(systemName: "chevron.right").font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
        }
        .tint(Rink.ice)
    }
}

// MARK: - Error state

/// Shown when the home summary can't load and there's nothing cached to fall back
/// on. Uses the native `ContentUnavailableView` with a system button so the retry
/// action sizes correctly and stays legible at every Dynamic Type size.
private struct HomeUnavailableView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Home Unavailable", systemImage: "wifi.exclamationmark")
        } description: {
            Text("We couldn't load the latest games right now.")
        } actions: {
            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Rink.ice)
        }
    }
}

// MARK: - Full standings (See All destination)

private struct AllStandingsView: View {
    let items: [StandingObj]
    let favoriteId: String?

    var body: some View {
        ScrollView {
            StandingsTable(title: "Standings", items: items, favoriteTeamId: favoriteId)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
        }
        .background(Rink.canvas)
        .navigationTitle("Standings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("Home · iPhone") {
    NavigationStack { HomeView(viewModel: .preview()) }
}

#Preview("Home · iPhone · Dark") {
    NavigationStack { HomeView(viewModel: .preview()) }
        .preferredColorScheme(.dark)
}

#Preview("Home · No favorite") {
    NavigationStack { HomeView(viewModel: .preview(.mockNoFavorite)) }
}

#Preview("Home · iPad", traits: .landscapeLeft) {
    NavigationStack { HomeView(viewModel: .preview()) }
}

#Preview("Home · Unavailable") {
    ZStack {
        RinkAmbientBackground(.arena)
        HomeUnavailableView(retry: {})
    }
}

#Preview("Home · Unavailable · Dark") {
    ZStack {
        RinkAmbientBackground(.arena)
        HomeUnavailableView(retry: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Home · Pre-season") {
    NavigationStack { HomeView(viewModel: .preview(.mockPreseason)) }
}

#Preview("Home · Pre-season · Dark") {
    NavigationStack { HomeView(viewModel: .preview(.mockPreseason)) }
        .preferredColorScheme(.dark)
}

#Preview("Home · Concluded") {
    NavigationStack { HomeView(viewModel: .preview(.mockConcluded)) }
}

#Preview("Home · Concluded · Dark") {
    NavigationStack { HomeView(viewModel: .preview(.mockConcluded)) }
        .preferredColorScheme(.dark)
}

#Preview("Home · Pre-season · iPad", traits: .landscapeLeft) {
    NavigationStack { HomeView(viewModel: .preview(.mockPreseason)) }
}
