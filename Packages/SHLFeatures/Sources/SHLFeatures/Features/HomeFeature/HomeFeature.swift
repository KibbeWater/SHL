//
//  HomeFeature.swift
//  SHLFeatures
//

import ComposableArchitecture
import Foundation
import SHLCore
import SHLNetwork

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var featuredGame: Match? = nil
        public var liveGame: LiveMatch? = nil
        public var latestMatches: [Match] = []
        public var standings: [Standings] = []
        public var standingsDisabled: Bool = false
        public var calendarLiveMatches: [String: LiveMatch] = [:]

        public init() {}
    }

    public enum Action {
        case onAppear
        case refreshed
        case dataLoaded(matches: [Match], featured: Match?, standings: [Standings])
        case liveUpdate(LiveMatch)
        case calendarLiveUpdate(LiveMatch)
        case featuredGameSelected(Match)
        case standingsLoaded([Standings])
        case standingsLoadFailed
        case featuredLiveLoaded(LiveMatch?)
        case calendarLiveLoaded(String, LiveMatch?)
        case matchTapped(String)
    }

    private enum CancelID {
        case featuredSSE
        case calendarSSE
        case polling
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.refreshed)
                }

            case .refreshed:
                return .run { send in
                    let recent = try await apiClient.getRecentMatches(10)
                    let allMatches = recent.upcoming + recent.recent

                    // Select featured game
                    let liveMatches = (try? await apiClient.getLiveMatches()) ?? []
                    let liveUUIDs = Set(liveMatches.map { $0.externalUUID })

                    let featured = await FeaturedGameAlgo.getFeaturedGame(
                        allMatches,
                        interestedTeams: Settings.shared.getInterestedTeamIds(),
                        favoriteTeamId: Settings.shared.getFavoriteTeamId(),
                        liveExternalUUIDs: liveUUIDs
                    )

                    let standings = (try? await apiClient.getCurrentStandings()) ?? []

                    await send(.dataLoaded(
                        matches: allMatches,
                        featured: featured,
                        standings: standings
                    ))
                }

            case let .dataLoaded(matches, featured, standings):
                state.latestMatches = matches
                state.featuredGame = featured
                state.standings = standings
                state.standingsDisabled = standings.isEmpty

                // Start SSE for featured game and calendar matches
                let featuredId = featured?.externalUUID
                let calendarIds = matches
                    .filter { !$0.played && Calendar.current.isDateInToday($0.date) }
                    .map { $0.externalUUID }

                return .merge(
                    // Fetch initial live data for featured game
                    featuredId.map { id in
                        Effect.run { send in
                            let live = try? await apiClient.getLiveMatch(id)
                            await send(.featuredLiveLoaded(live))
                        }
                    } ?? .none,
                    // Fetch initial live data for calendar matches
                    .merge(calendarIds.map { id in
                        Effect.run { send in
                            let live = try? await apiClient.getLiveMatch(id)
                            await send(.calendarLiveLoaded(id, live))
                        }
                    }),
                    // Poll for featured game updates
                    featuredId.map { id in
                        Effect.run { send in
                            while !Task.isCancelled {
                                try await Task.sleep(for: .seconds(30))
                                let live = try? await apiClient.getLiveMatch(id)
                                await send(.featuredLiveLoaded(live))
                            }
                        }
                        .cancellable(id: CancelID.polling, cancelInFlight: true)
                    } ?? .none
                )

            case let .liveUpdate(liveMatch):
                if liveMatch.gameState == .played {
                    state.liveGame = nil
                } else {
                    state.liveGame = liveMatch
                }
                return .none

            case let .calendarLiveUpdate(liveMatch):
                if liveMatch.gameState == .played {
                    state.calendarLiveMatches.removeValue(forKey: liveMatch.externalId)
                } else {
                    state.calendarLiveMatches[liveMatch.externalId] = liveMatch
                }
                return .none

            case let .featuredGameSelected(match):
                state.featuredGame = match
                return .run { send in
                    let live = try? await apiClient.getLiveMatch(match.externalUUID)
                    await send(.featuredLiveLoaded(live))
                }

            case let .standingsLoaded(standings):
                state.standings = standings
                state.standingsDisabled = false
                return .none

            case .standingsLoadFailed:
                state.standingsDisabled = true
                return .none

            case let .featuredLiveLoaded(live):
                if let live, live.gameState != .played {
                    state.liveGame = live
                } else {
                    state.liveGame = nil
                }
                return .none

            case let .calendarLiveLoaded(id, live):
                if let live, live.gameState != .played {
                    state.calendarLiveMatches[id] = live
                } else {
                    state.calendarLiveMatches.removeValue(forKey: id)
                }
                return .none

            case .matchTapped:
                // Handled by parent (AppFeature) for navigation
                return .none
            }
        }
    }
}
