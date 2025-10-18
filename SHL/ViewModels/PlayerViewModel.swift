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
    private let api = SHLAPIClient.shared
    private var player: LineupPlayer

    @Published var info: Player? = nil
    @Published var stats: [PlayerGameLog] = []

    init(_ player: LineupPlayer) {
        self.player = player

        Task {
            try? await refresh()
        }
    }

    func refresh() async throws {
        self.info = try await api.getPlayerDetail(id: player.uuid)
        if let info {
            self.stats = (try? await api.getPlayerGameLog(id: info.id)) ?? []
        }
    }
}
