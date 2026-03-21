//
//  AppFeature.swift
//  SHLFeatures
//
//  Root reducer composing all tab features.
//  Both Root_iOS and Root_iPadOS consume this same store.
//

import ComposableArchitecture
import SHLNetwork

@Reducer
public struct AppFeature {
    public enum Tab: Equatable, Hashable {
        case home
        case schedule
        case settings
    }

    @ObservableState
    public struct State {
        public var selectedTab: Tab = .home
        public var home = HomeFeature.State()
        public var matchList = MatchListFeature.State()
        public var settings = SettingsFeature.State()
        public var teamTabs: IdentifiedArrayOf<TeamFeature.State> = []

        public init() {}
    }

    public enum Action {
        case tabSelected(Tab)
        case home(HomeFeature.Action)
        case matchList(MatchListFeature.Action)
        case settings(SettingsFeature.Action)
        case teamTabs(IdentifiedActionOf<TeamFeature>)
        case deepLink(matchId: String, source: String)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.matchList, action: \.matchList) {
            MatchListFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case let .deepLink(matchId, _):
                state.selectedTab = .home
                return .send(.home(.matchTapped(matchId)))

            case .home, .matchList, .settings, .teamTabs:
                return .none
            }
        }
        .forEach(\.teamTabs, action: \.teamTabs) {
            TeamFeature()
        }
    }
}
