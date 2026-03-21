//
//  TeamFeature.swift
//  SHLFeatures
//

import ComposableArchitecture
import Foundation
import SHLNetwork

@Reducer
public struct TeamFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: String { team.id }
        public var team: Team
        public var roster: [Player] = []
        public var matches: [Match] = []
        public var standings: [Standings] = []

        public init(team: Team) {
            self.team = team
        }
    }

    public enum Action {
        case onAppear
        case refreshed
        case rosterLoaded([Player])
        case matchesLoaded([Match])
        case standingsLoaded([Standings])
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
                let teamId = state.team.id
                return .run { send in
                    async let roster = try? apiClient.getTeamRoster(teamId)
                    async let standings = try? apiClient.getCurrentStandings()
                    async let matches = try? apiClient.getTeamMatches(teamId)

                    if let r = await roster {
                        await send(.rosterLoaded(r))
                    }
                    if let s = await standings {
                        await send(.standingsLoaded(s))
                    }
                    if let m = await matches {
                        await send(.matchesLoaded(m.sorted { $0.date > $1.date }))
                    }
                }

            case let .rosterLoaded(players):
                state.roster = players
                return .none

            case let .matchesLoaded(matches):
                state.matches = matches
                return .none

            case let .standingsLoaded(standings):
                state.standings = standings
                return .none
            }
        }
    }
}
