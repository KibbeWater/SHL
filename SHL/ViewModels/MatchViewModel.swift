//
//  MatchViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit
import Combine
import SwiftUI

@MainActor
class MatchViewModel: ObservableObject {
    private var api: HockeyAPI? = nil

    @Published var matchStats: GameStats? = nil
    @Published var matchExtra: GameExtra? = nil
    @Published var pbp: PBPEvents? = nil
    
    @Published var home: SiteTeam? = nil
    @Published var away: SiteTeam? = nil
    
    @Published var liveGame: GameData? = nil
    private var cancellable: AnyCancellable?
    
    private var match: Game
    
    init(_ match: Game) {
        self.match = match
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    func setAPI(_ api: HockeyAPI) {
        self.api = api
        
        Task {
            try? await refresh()
        }
        
        listenForLiveGame()
    }
    
    func refresh() async throws {
        matchStats = try? await api?.match.getMatchStats(match)
        matchExtra = try await api?.match.getMatchExtra(match)
        
        if let matchExtra { // Yes, technically this will always be true, but we need to make sure it's not nil to satisfy the compiler
            try await fetchTeam(matchExtra)
        }
        
        try await refreshPBP()
    }
    
    func refreshPBP() async throws {
        pbp = try await api?.match.getMatchPBP(match)
    }
    
    func fetchTeam(_ extra: GameExtra) async throws {
        home = try? await api?.team.getTeam(withId: extra.homeTeam.uuid)
        away = try? await api?.team.getTeam(withId: extra.awayTeam.uuid)
    }
    
    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }
        
        cancellable = api?.listener.subscribe()
            .sink { [weak self] event in
                if self?.match.id == event.gameOverview.gameUuid {
                    self?.liveGame = event
                }
            }
    }
}
