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
    static var shared: LiveMatchListener = .init()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.listener = HockeyAPI().listener
        listener.connect()
    }

    /// Subscribe to live updates for specific match IDs
    /// - Parameters:
    ///   - matchIds: Array of match IDs to listen to. If empty, subscribes to all matches.
    ///   - matchProvider: Closure that provides Match and Team data for a given gameUuid
    /// - Returns: Publisher that emits LiveMatch events
    func subscribe(
        _ matchIds: [String] = [],
        matchProvider: @escaping (String) async -> (match: Match, homeTeam: Team, awayTeam: Team)?
    ) -> AnyPublisher<LiveMatch, Never> {
        return listener.subscribe(matchIds)
            .flatMap { gameData -> AnyPublisher<LiveMatch?, Never> in
                let gameUuid = gameData.gameOverview.gameUuid

                return Future<LiveMatch?, Never> { promise in
                    Task {
                        if let data = await matchProvider(gameUuid) {
                            let liveMatch = LiveMatch.fromGameData(
                                gameData,
                                match: data.match,
                                homeTeam: data.homeTeam,
                                awayTeam: data.awayTeam
                            )
                            promise(.success(liveMatch))
                        } else {
                            promise(.success(nil))
                        }
                    }
                }.eraseToAnyPublisher()
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Subscribe to live updates for specific match IDs (returns raw GameData)
    /// - Parameter matchIds: Array of match IDs to listen to. If empty, subscribes to all matches.
    /// - Returns: Publisher that emits GameData events
    func subscribeRaw(_ matchIds: [String] = []) -> AnyPublisher<GameData, Never> {
        return listener.subscribe(matchIds)
    }

    /// Request initial data for specific match IDs
    /// - Parameter matchIds: Array of match IDs to fetch
    func requestInitialData(_ matchIds: [String]) {
        listener.requestInitialData(matchIds)
    }
}
