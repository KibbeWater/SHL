//
//  MatchDetailFeature.swift
//  SHLFeatures
//

import ComposableArchitecture
import Foundation
import SHLNetwork

@Reducer
public struct MatchDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var match: Match
        public var matchDetail: Match? = nil
        public var matchStats: [MatchStats] = []
        public var pbpEvents: [PBPEventDTO] = []
        public var liveGame: LiveMatch? = nil
        public var homeTeam: Team? = nil
        public var awayTeam: Team? = nil

        public init(match: Match) {
            self.match = match
        }
    }

    public enum Action {
        case onAppear
        case refreshed
        case liveUpdate(LiveMatch)
        case startActivity
        case statsLoaded([MatchStats])
        case pbpLoaded([PBPEventDTO])
        case detailLoaded(Match)
        case teamsLoaded(home: Team?, away: Team?)
        case liveLoaded(LiveMatch?)
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
                let matchId = state.match.id
                let externalUUID = state.match.externalUUID
                return .run { send in
                    // Fetch match detail
                    let detail = try await apiClient.getMatchDetail(matchId)
                    await send(.detailLoaded(detail))

                    // Fetch live data
                    let live = try? await apiClient.getLiveMatch(externalUUID)
                    await send(.liveLoaded(live))

                    // Fetch teams
                    let home: Team? = if let homeId = detail.homeTeam.id {
                        try? await apiClient.getTeamDetail(homeId)
                    } else {
                        nil
                    }
                    let away: Team? = if let awayId = detail.awayTeam.id {
                        try? await apiClient.getTeamDetail(awayId)
                    } else {
                        nil
                    }
                    await send(.teamsLoaded(home: home, away: away))

                    // Fetch stats
                    let stats = (try? await apiClient.getMatchStats(matchId)) ?? []
                    await send(.statsLoaded(stats))

                    // Fetch PBP events
                    let events = (try? await apiClient.getMatchEvents(matchId)) ?? []
                    await send(.pbpLoaded(events))
                }

            case let .liveUpdate(liveMatch):
                state.liveGame = liveMatch
                return .none

            case .startActivity:
                // Handled by parent or side effect in the app layer
                return .none

            case let .statsLoaded(stats):
                state.matchStats = stats
                return .none

            case let .pbpLoaded(events):
                state.pbpEvents = events
                return .none

            case let .detailLoaded(detail):
                state.matchDetail = detail
                return .none

            case let .teamsLoaded(home, away):
                state.homeTeam = home
                state.awayTeam = away

                // Start polling for live updates now that teams are loaded
                let externalUUID = state.match.externalUUID
                return Effect.run { send in
                    while !Task.isCancelled {
                        try await Task.sleep(for: .seconds(30))
                        if let live = try? await apiClient.getLiveMatch(externalUUID) {
                            await send(.liveUpdate(live))
                        }
                        // PBP refresh could be added here using match.id
                    }
                }
                .cancellable(id: CancelID.polling, cancelInFlight: true)

            case let .liveLoaded(live):
                state.liveGame = live
                return .none
            }
        }
    }
}
