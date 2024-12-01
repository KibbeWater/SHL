//
//  PlayerViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit
import SwiftUI

@MainActor
class PlayerViewModel: ObservableObject {
    private var api: HockeyAPI? = nil
    private var player: LineupPlayer
    
    @Published var info: Player? = nil
    @Published var stats: [PlayerGameLog] = []

    init(_ player: LineupPlayer) {
        self.player = player
        
    }
    
    func setAPI(_ api: HockeyAPI) {
        self.api = api
        
        Task {
            try? await refresh()
        }
    }
    
    func refresh() async throws {
        self.info = try await api?.player.getPlayer(withId: player.uuid)
        if let info {
            self.stats = try await api?.player.getGameLog(info) ?? []
        }
    }
}
