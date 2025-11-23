//
//  LiveMatchListener.swift
//  SHL
//
//  Created by Migration Script
//  Migrated to native SSE implementation
//

import Combine
import Foundation

/// Native live match listener using SSE connection
/// Provides live game updates with connection quality monitoring
class LiveMatchListener: ObservableObject {
    static var shared: LiveMatchListener = .init()

    @Published private(set) var metrics: ConnectionMetrics
    private let connectionManager: SSEConnectionManager
    private var cancellables: Set<AnyCancellable> = []
    private var activeSubscriptions: Set<AnyCancellable> = []

    init() {
        let metricsInstance = ConnectionMetrics()
        self.metrics = metricsInstance
        self.connectionManager = SSEConnectionManager(metrics: metricsInstance)
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
        let subject = PassthroughSubject<LiveMatch, Never>()

        Task {
            // First, send any cached data
            if matchIds.isEmpty {
                let cachedUpdates = await connectionManager.getAllCachedUpdates()
                for update in cachedUpdates {
                    if let data = await matchProvider(update.gameUuid) {
                        let liveMatch = LiveMatch.fromLiveGameUpdate(
                            update,
                            match: data.match,
                            homeTeam: data.homeTeam,
                            awayTeam: data.awayTeam
                        )
                        subject.send(liveMatch)
                    }
                }
            } else {
                for gameUuid in matchIds {
                    if let update = await connectionManager.getCachedUpdate(for: gameUuid) {
                        if let data = await matchProvider(gameUuid) {
                            let liveMatch = LiveMatch.fromLiveGameUpdate(
                                update,
                                match: data.match,
                                homeTeam: data.homeTeam,
                                awayTeam: data.awayTeam
                            )
                            subject.send(liveMatch)
                        }
                    }
                }
            }

            // Then subscribe to live stream
            let stream = await connectionManager.subscribe()
            for await update in stream {
                // Filter by matchIds if specified
                if !matchIds.isEmpty && !matchIds.contains(update.gameUuid) {
                    continue
                }

                // Get match data and transform
                if let data = await matchProvider(update.gameUuid) {
                    let liveMatch = LiveMatch.fromLiveGameUpdate(
                        update,
                        match: data.match,
                        homeTeam: data.homeTeam,
                        awayTeam: data.awayTeam
                    )
                    subject.send(liveMatch)
                }
            }

            subject.send(completion: .finished)
        }

        return subject.eraseToAnyPublisher()
    }

    /// Request initial data for specific match IDs
    /// Returns cached data immediately if available
    /// - Parameter matchIds: Array of match IDs to fetch
    func requestInitialData(_ matchIds: [String]) {
        Task {
            // With our implementation, cached data is automatically sent on subscribe
            // This method is kept for backward compatibility but doesn't need to do anything
            // since subscribe() already sends cached data immediately
        }
    }

    /// Disconnect from SSE stream
    func disconnect() {
        Task {
            await connectionManager.disconnect()
        }
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        activeSubscriptions.forEach { $0.cancel() }
    }
}
