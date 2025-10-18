//
//  TeamViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit
import SwiftUI

@MainActor
class TeamViewModel: ObservableObject {
    private let api = SHLAPIClient.shared
    private var team: TeamDetail

    @Published var lineup: TeamLineup? = nil
    @Published var history: [Match] = []
    @Published var standings: Standings? = nil

    init(_ team: TeamDetail) {
        self.team = team

        Task {
            try? await refresh()
        }
    }

    func refresh() async throws  {
        self.lineup = try? await api.getTeamLineup(id: team.id)
        if let ssgtUuid = try? await api.getCurrentSsgt() {
            self.standings = try? await api.getStandings(ssgtUuid: ssgtUuid)
        }
        if let season = try? await api.getCurrentSeason() {
            guard let series = try? await api.getCurrentSeries() else { return }

            self.history = (try? await api.getSchedule(seasonId: season.id, seriesId: series.id, teamIds: [team.id])) ?? []
        }
    }
}
