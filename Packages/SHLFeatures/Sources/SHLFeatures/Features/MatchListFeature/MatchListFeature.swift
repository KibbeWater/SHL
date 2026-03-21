//
//  MatchListFeature.swift
//  SHLFeatures
//

import ComposableArchitecture
import Foundation
import SHLNetwork

@Reducer
public struct MatchListFeature {
    @ObservableState
    public struct State: Equatable {
        public var latestMatches: [Match] = []
        public var previousMatches: [Match] = []
        public var todayMatches: [Match] = []
        public var upcomingMatches: [Match] = []
        public var selectedTab: Tab = .today
        public var liveMatches: [String: LiveMatch] = [:]

        public enum Tab: String, Equatable, CaseIterable {
            case previous, today, upcoming
        }

        public init() {}
    }

    public enum Action {
        case onAppear
        case refreshed
        case matchesLoaded([Match])
        case matchTapped(Match)
        case liveUpdate(LiveMatch)
        case tabChanged(State.Tab)
        case liveDataLoaded(String, LiveMatch?)
    }

    private enum CancelID {
        case sseSubscription
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
                    let season = try await apiClient.getCurrentSeason()
                    let matches = (try? await apiClient.getSeasonMatches(season.code)) ?? []
                    await send(.matchesLoaded(matches))
                }

            case let .matchesLoaded(matches):
                state.latestMatches = matches
                filterMatches(state: &state)
                removeUnusedListeners(state: &state)

                let todayIds = state.todayMatches.map { $0.externalUUID }

                return .merge(
                    // Fetch initial live data for today's matches
                    .merge(todayIds.map { id in
                        Effect.run { send in
                            let live = try? await apiClient.getLiveMatch(id)
                            await send(.liveDataLoaded(id, live))
                        }
                    }),
                    // Poll for live match updates
                    todayIds.isEmpty ? .none :
                        Effect.run { [todayIds] send in
                            while !Task.isCancelled {
                                try await Task.sleep(for: .seconds(30))
                                for id in todayIds {
                                    let live = try? await apiClient.getLiveMatch(id)
                                    await send(.liveDataLoaded(id, live))
                                }
                            }
                        }
                        .cancellable(id: CancelID.polling, cancelInFlight: true)
                )

            case let .matchTapped(match):
                // Handled by parent feature or navigation coordinator
                _ = match
                return .none

            case let .liveUpdate(liveMatch):
                if liveMatch.gameState == .played {
                    state.liveMatches.removeValue(forKey: liveMatch.externalId)
                } else {
                    state.liveMatches[liveMatch.externalId] = liveMatch
                }
                return .none

            case let .tabChanged(tab):
                state.selectedTab = tab
                return .none

            case let .liveDataLoaded(id, live):
                if let live, live.gameState != .played {
                    state.liveMatches[id] = live
                } else {
                    state.liveMatches.removeValue(forKey: id)
                }
                return .none
            }
        }
    }

    // MARK: - Helpers

    private func filterMatches(state: inout State) {
        let now = Date()
        let calendar = Calendar.current

        state.previousMatches = state.latestMatches
            .filter { $0.date < calendar.startOfDay(for: now) }
            .sorted { $0.date > $1.date }

        state.todayMatches = state.latestMatches
            .filter { calendar.isDateInToday($0.date) }

        state.upcomingMatches = state.latestMatches
            .filter {
                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return false }
                return calendar.startOfDay(for: $0.date) >= tomorrow
            }
    }

    private func removeUnusedListeners(state: inout State) {
        let todayIds = Set(state.todayMatches.map { $0.externalUUID })
        state.liveMatches = state.liveMatches.filter { todayIds.contains($0.key) }
    }
}
