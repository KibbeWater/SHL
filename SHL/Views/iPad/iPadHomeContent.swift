//
//  iPadHomeContent.swift
//  SHL
//
//  Full-screen iPad home view with adaptive grid layout
//

import SwiftUI

struct iPadHomeContent: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ObservedObject var viewModel: HomeViewModel
    var onSelectMatch: (Match) -> Void

    private var upcomingMatches: [Match] {
        viewModel.latestMatches
            .filter { !$0.concluded }
            .sorted(by: { $0.date < $1.date })
    }

    private var recentResults: [Match] {
        viewModel.latestMatches
            .filter { $0.concluded }
            .sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Featured game — full width
                featuredGameSection
                    .padding(.horizontal)

                // Two-column layout: left (calendar + recent) / right (standings)
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 20) {
                        // Left column
                        VStack(spacing: 16) {
                            matchCalendarSection
                            recentResultsSection
                        }
                        .frame(maxWidth: .infinity)

                        // Right column
                        standingsSection
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                } else {
                    // Compact: stack vertically
                    VStack(spacing: 16) {
                        matchCalendarSection
                        recentResultsSection
                        standingsSection
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Home")
        .onChange(of: viewModel.featuredGame) { _, _ in
            guard let featured = viewModel.featuredGame else { return }
            viewModel.selectListenedGame(featured)
        }
        .refreshable {
            try? await viewModel.refresh(hard: true)
        }
    }

    // MARK: - Featured Game

    @ViewBuilder
    private var featuredGameSection: some View {
        if let featured = viewModel.featuredGame {
            Button {
                onSelectMatch(featured)
            } label: {
                iPadFeaturedGame(
                    game: featured,
                    liveGame: viewModel.liveGame
                )
            }
            .buttonStyle(.plain)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: 160)
                .overlay {
                    ProgressView()
                }
        }
    }

    // MARK: - Match Calendar

    private var matchCalendarSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Upcoming", systemImage: "calendar")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            if upcomingMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No upcoming matches")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(upcomingMatches.prefix(5)), id: \.id) { match in
                        Button {
                            onSelectMatch(match)
                        } label: {
                            MatchCardCompact(
                                game: match,
                                liveGame: viewModel.calendarLiveMatches[match.externalUUID]
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            #if !APPCLIP
                            ReminderContext(game: match)
                            #endif
                        }
                    }
                }
                .padding(8)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent Results

    private var recentResultsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Recent Results", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            if recentResults.isEmpty {
                VStack(spacing: 8) {
                    Text("No recent results")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(recentResults.prefix(5)), id: \.id) { match in
                        Button {
                            onSelectMatch(match)
                        } label: {
                            MatchCardCompact(game: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Standings

    private var standingsSection: some View {
        Group {
            if viewModel.standingsDisabled {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Standings unavailable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let standings = viewModel.standings {
                StandingsTable(
                    title: "Standings",
                    items: standings,
                    favoriteTeamId: Settings.shared.getFavoriteTeamId()
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
