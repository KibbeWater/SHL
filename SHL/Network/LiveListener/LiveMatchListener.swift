//
//  LiveMatchListener.swift
//  SHL
//
//  Created by Migration Script
//

import Combine
import Foundation
import HockeyKit

/// Wrapper class for HockeyKit's live match listener functionality.
/// This is the ONLY class that should import and use HockeyKit in the app.
class LiveMatchListener: ObservableObject {
    private let listener: ListenerServiceProtocol

    init() {
        self.listener = HockeyAPI().listener
    }

    /// Subscribe to live updates for specific match IDs
    /// - Parameter matchIds: Array of match IDs to listen to. If empty, subscribes to all matches.
    /// - Returns: Publisher that emits GameData events
    func subscribe(_ matchIds: [String] = []) -> AnyPublisher<GameData, Never> {
        return listener.subscribe(matchIds)
    }

    /// Request initial data for specific match IDs
    /// - Parameter matchIds: Array of match IDs to fetch
    func requestInitialData(_ matchIds: [String]) {
        listener.requestInitialData(matchIds)
    }
}
