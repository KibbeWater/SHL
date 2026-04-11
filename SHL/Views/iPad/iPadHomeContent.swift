//
//  iPadHomeContent.swift
//  SHL
//
//  iPad home content column with adaptive grid layout
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

    private var columns: [GridItem] {
        sizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Featured game
                if let featured = viewModel.featuredGame {
                    Button {
                        onSelectMatch(featured)
                    } label: {
                        LargeOverview(
                            game: featured,
                            liveGame: viewModel.liveGame
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 96)
                        .padding(.horizontal)
                }

                // Adaptive grid: calendar + standings
                LazyVGrid(columns: columns, spacing: 20) {
                    // Match Calendar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Match Calendar")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }

                        if upcomingMatches.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("No upcoming matches")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(upcomingMatches.prefix(5))) { match in
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
                        }
                    }

                    // Standings
                    VStack(spacing: 8) {
                        if viewModel.standingsDisabled {
                            HStack {
                                Text("Standings are temporarily unavailable")
                                    .font(.callout)
                                Spacer()
                            }
                        } else if let standings = viewModel.standings {
                            StandingsTable(
                                title: "Leaderboard",
                                items: standings,
                                favoriteTeamId: Settings.shared.getFavoriteTeamId()
                            )
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: viewModel.featuredGame) { _, _ in
            guard let featured = viewModel.featuredGame else { return }
            viewModel.selectListenedGame(featured)
        }
        .refreshable {
            try? await viewModel.refresh(hard: true)
        }
    }
}
