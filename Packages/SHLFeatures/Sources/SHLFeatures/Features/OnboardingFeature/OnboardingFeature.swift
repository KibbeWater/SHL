//
//  OnboardingFeature.swift
//  SHLFeatures
//

import ComposableArchitecture
import SHLNetwork
import SHLCore

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State {
        public var currentPage: Int = 0
        public var selectedTeamIds: Set<String> = []
        public var favoriteTeamId: String?
        public var userManagementEnabled: Bool = false
        public var allTeams: [Team] = []

        public init() {}
    }

    public enum Action {
        case onAppear
        case teamsLoaded([Team])
        case nextPage
        case previousPage
        case toggleTeam(String)
        case setFavoriteTeam(String?)
        case toggleUserManagement(Bool)
        case completeOnboarding
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let teams = try await apiClient.getTeams()
                    await send(.teamsLoaded(teams))
                }

            case let .teamsLoaded(teams):
                state.allTeams = teams
                return .none

            case .nextPage:
                state.currentPage += 1
                return .none

            case .previousPage:
                state.currentPage = max(0, state.currentPage - 1)
                return .none

            case let .toggleTeam(teamId):
                if state.selectedTeamIds.contains(teamId) {
                    state.selectedTeamIds.remove(teamId)
                    if state.favoriteTeamId == teamId {
                        state.favoriteTeamId = nil
                    }
                } else {
                    state.selectedTeamIds.insert(teamId)
                }
                return .none

            case let .setFavoriteTeam(teamId):
                state.favoriteTeamId = teamId
                return .none

            case let .toggleUserManagement(enabled):
                state.userManagementEnabled = enabled
                return .none

            case .completeOnboarding:
                let selectedIds = state.selectedTeamIds
                let favoriteId = state.favoriteTeamId
                let userMgmt = state.userManagementEnabled
                let allTeams = state.allTeams

                return .run { _ in
                    let interestedTeams = allTeams
                        .filter { selectedIds.contains($0.id) }
                        .map { InterestedTeam(id: $0.id, name: $0.name, code: $0.code, city: $0.city) }

                    await MainActor.run {
                        Settings.shared.setInterestedTeams(interestedTeams)
                        Settings.shared.setFavoriteTeamId(favoriteId)
                        Settings.shared.userManagementEnabled = userMgmt
                        Settings.shared.completeOnboarding()
                    }
                }
            }
        }
    }
}
