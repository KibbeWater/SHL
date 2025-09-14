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
    private var api: HockeyAPI? = nil
    private var team: SiteTeam
    
    @Published var lineup: [TeamLineup] = []
    @Published var history: [Game] = []
    @Published var standings: Standings? = nil
    
    init(_ team: SiteTeam) {
        self.team = team
    }
    
    func setAPI(_ api: HockeyAPI) {
        self.api = api
        
        Task {
            try? await refresh()
        }
    }
    
    func refresh() async throws  {
        self.lineup = (try? await api?.team.getLineup(team: self.team)) ?? []
        if let ssgtUuid = try await api?.season.getCurrentSsgt() {
            self.standings = (try? await api?.standings.getStandings(ssgtUuid: ssgtUuid))
        }
        if let season = try await api?.season.getCurrent() {
            guard let series = try? await api?.series.getCurrentSeries() else { return }
            
            self.history = try await api?.match.getSeasonSchedule(season, series: series, withTeams: [team.id]) ?? []
        }
    }
}
