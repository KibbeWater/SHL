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

        // Create a publisher for initial cached data using Future
        // Future waits for the async work to complete before emitting,
        // ensuring subscribers receive cached data regardless of timing
        let initialDataPublisher = Future<[LiveMatch], Never> { promise in
            Task {
                var initialMatches: [LiveMatch] = []

                let updates: [LiveGameUpdate]
                if matchIds.isEmpty {
                    updates = await self.connectionManager.getAllCachedUpdates()
                } else {
                    var fetchedUpdates: [LiveGameUpdate] = []
                    for gameUuid in matchIds {
                        if let update = await self.connectionManager.getCachedUpdate(for: gameUuid) {
                            fetchedUpdates.append(update)
                        }
                    }
                    updates = fetchedUpdates
                }

                for update in updates {
                    if let data = await matchProvider(update.gameUuid) {
                        let liveMatch = LiveMatch.fromLiveGameUpdate(
                            update,
                            match: data.match,
                            homeTeam: data.homeTeam,
                            awayTeam: data.awayTeam
                        )
                        initialMatches.append(liveMatch)
                    }
                }

                promise(.success(initialMatches))
            }
        }
        .flatMap { matches in
            Publishers.Sequence(sequence: matches)
        }
        .eraseToAnyPublisher()

        // Start live stream subscription in background
        Task {
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

        // Merge: initial cached data first, then live stream updates
        return Publishers.Merge(initialDataPublisher, subject)
            .eraseToAnyPublisher()
    }

    /// Request initial data for specific match IDs
    /// - Note: Deprecated. subscribe() now reliably delivers cached data via
    ///         Publishers.Merge with Future. This method is kept for backward
    ///         compatibility but is a no-op.
    /// - Parameter matchIds: Array of match IDs to fetch (ignored)
    @available(*, deprecated, message: "No longer needed - subscribe() delivers cached data reliably")
    func requestInitialData(_ matchIds: [String]) {
        // No-op: subscribe() now uses Future + Merge to ensure cached data
        // reaches subscribers regardless of connection timing
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
