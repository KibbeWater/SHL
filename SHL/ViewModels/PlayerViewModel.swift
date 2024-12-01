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
    @EnvironmentObject private var api: HockeyAPI
    private var player: LineupPlayer
    
    @Published var info: Player? = nil
    @Published var stats: [PlayerGameLog] = []

    init(_ api: HockeyAPI, player: LineupPlayer) {
        self.player = player
        
        Task {
            try? await refresh()
        }
    }
    
    func refresh() async throws {
        self.info = try await api.player.getPlayer(withId: player.uuid)
        if let info {
            self.stats = try await api.player.getGameLog(info)
        }
    }
}
