//
//  TeamViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import SwiftUI

@MainActor
class TeamViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private var team: Team

    @Published var lineup: [Player] = []
    @Published var history: [Match] = []
    @Published var standings: [Standings] = []

    init(_ team: Team) {
        self.team = team

        Task {
            try? await refresh()
        }
    }

    func refresh() async throws  {
        self.lineup = (try? await api.getTeamRoster(id: team.id)) ?? []
        self.standings = (try? await api.getCurrentStandings()) ?? []
        self.history = (try? await api.getTeamMatches(id: team.id)) ?? []
    }
}
