//
//  TeamViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit

@MainActor
class TeamViewModel: ObservableObject {
    private var api: HockeyAPI
    private var team: SiteTeam
    
    @Published var lineup: [TeamLineup] = []
    @Published var history: [Game] = []
    @Published var standings: Standings? = nil
    
    init(_ api: HockeyAPI, team: SiteTeam) {
        self.api = api
        self.team = team
        
        Task {
            try? await refresh()
        }
    }
    
    func refresh() async throws  {
        self.lineup = try await api.team.getLineup(team: self.team)
        if let series = try? await api.series.getCurrentSeries() {
            self.standings = try await api.standings.getStandings(series: series)
        }
        if let season = try? await api.season.getCurrent() {
            self.history = try await api.match.getSeasonSchedule(season, withTeams: [team.id])
        }
    }
}
