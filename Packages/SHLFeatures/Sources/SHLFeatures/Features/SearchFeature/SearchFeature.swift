//
//  SearchFeature.swift
//  SHLFeatures
//

import ComposableArchitecture
import SHLNetwork

@Reducer
public struct SearchFeature {
    @ObservableState
    public struct State {
        public var query: String = ""
        public var results: [Match] = []
        public var isSearching: Bool = false

        public init() {}
    }

    public enum Action {
        case queryChanged(String)
        case search
        case searchCompleted([Match])
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .queryChanged(query):
                state.query = query
                return .none

            case .search:
                state.isSearching = true
                let query = state.query
                return .run { send in
                    let response = try await apiClient.searchMatches(nil, query, nil, nil, false, 1, 20)
                    await send(.searchCompleted(response.data))
                }

            case let .searchCompleted(matches):
                state.results = matches
                state.isSearching = false
                return .none
            }
        }
    }
}
