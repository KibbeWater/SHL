//
//  SSEConnectionManager.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation

/// Manages SSE connection to the live game broadcaster
actor SSEConnectionManager {
    // MARK: - Constants

    private let sseURL = URL(string: "https://game-broadcaster.s8y.se/live/game")!
    private let keepAliveTimeout: TimeInterval = 30
    private let maxReconnectDelay: TimeInterval = 60
    private let initialReconnectDelay: TimeInterval = 1

    // MARK: - Private Properties

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var buffer = SSEBuffer()
    private var continuations: [UUID: AsyncStream<LiveGameUpdate>.Continuation] = [:]
    private var cache: [String: LiveGameUpdate] = [:]
    private var reconnectAttempts = 0
    private var lastDataReceivedAt: Date?
    private var isConnecting = false

    private let metrics: ConnectionMetrics

    // MARK: - Initialization

    init(metrics: ConnectionMetrics) {
        self.metrics = metrics
    }

    deinit {
        // Clean up resources to prevent memory leaks
        session?.invalidateAndCancel()
        session = nil
        dataTask = nil
    }

    // MARK: - Public API

    /// Subscribe to live game updates
    /// - Returns: AsyncStream of LiveGameUpdate events
    func subscribe() -> AsyncStream<LiveGameUpdate> {
        let id = UUID()

        return AsyncStream { continuation in
            Task {
                await self.addContinuation(id, continuation: continuation)
                await self.ensureConnected()

                continuation.onTermination = { [weak self] _ in
                    Task {
                        await self?.removeContinuation(id)
                    }
                }
            }
        }
    }

    /// Get cached game update for a specific game
    func getCachedUpdate(for gameUuid: String) -> LiveGameUpdate? {
        return cache[gameUuid]
    }

    /// Get all cached game updates
    func getAllCachedUpdates() -> [LiveGameUpdate] {
        return Array(cache.values)
    }

    /// Disconnect and clean up
    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnecting = false

        Task { @MainActor in
            metrics.recordDisconnection()
        }
    }

    // MARK: - Connection Management

    private func ensureConnected() {
        guard session == nil && !isConnecting else { return }

        isConnecting = true
        connect()
    }

    private func connect() {
        Task { @MainActor in
            metrics.recordConnectionAttempt()
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = .infinity
        config.timeoutIntervalForResource = .infinity

        let delegate = SSEDelegate(onData: { [weak self] data in
            await self?.handleData(data)
        }, onComplete: { [weak self] error in
            await self?.handleCompletion(error: error)
        })

        session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        dataTask = session?.dataTask(with: sseURL)
        dataTask?.resume()

        isConnecting = false

        Task { @MainActor in
            metrics.recordConnectionSuccess()
        }
    }

    private func reconnect() {
        disconnect()

        let delay = min(
            initialReconnectDelay * pow(2.0, Double(reconnectAttempts)),
            maxReconnectDelay
        )

        reconnectAttempts += 1

        Task { @MainActor in
            metrics.recordReconnection()
        }

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self.connect()
        }
    }

    // MARK: - Data Handling

    private func handleData(_ data: Data) async {
        await buffer.append(data)
        lastDataReceivedAt = Date()

        while let event = await buffer.extractEvent() {
            if let update = parseSSEEvent(event) {
                // Update cache
                // Note: We don't implement timestamp-based deduplication because the SSE API
                // doesn't provide event timestamps in the payload. Out-of-order events are
                // rare in practice due to TCP's ordering guarantees. If out-of-order updates
                // become an issue, the upstream API would need to include timestamps in events.
                cache[update.gameUuid] = update

                // Broadcast to all subscribers
                for continuation in continuations.values {
                    continuation.yield(update)
                }

                Task { @MainActor in
                    metrics.recordDataReceived()
                }
            }
        }
    }

    private func handleCompletion(error: Error?) {
        if let error = error {
            Task { @MainActor in
                metrics.recordError(error)
            }
        }

        // Check if we should reconnect
        if let lastReceived = lastDataReceivedAt,
           Date().timeIntervalSince(lastReceived) < keepAliveTimeout {
            // Recent data, unexpected disconnect - reconnect
            reconnect()
        } else {
            // No recent data, might be intentional disconnect
            disconnect()
        }
    }

    // MARK: - SSE Parsing

    private func parseSSEEvent(_ event: String) -> LiveGameUpdate? {
        // SSE events come as "data: {json}\n\n"
        let lines = event.components(separatedBy: "\n")

        for line in lines {
            if line.hasPrefix("data:") {
                let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                guard let jsonData = jsonString.data(using: .utf8) else { continue }

                do {
                    let gameData = try JSONDecoder().decode(GameData.self, from: jsonData)
                    return translateToLiveGameUpdate(gameData)
                } catch {
                    Task { @MainActor in
                        metrics.recordError(error)
                    }
                }
            }
        }

        return nil
    }

    private func translateToLiveGameUpdate(_ gameData: GameData) -> LiveGameUpdate {
        let overview = gameData.gameOverview

        return LiveGameUpdate(
            gameUuid: overview.gameUuid,
            gameId: overview.gameId,
            homeTeam: LiveGameUpdate.TeamInfo(
                code: overview.homeTeam.code,
                score: overview.homeGoals
            ),
            awayTeam: LiveGameUpdate.TeamInfo(
                code: overview.awayTeam.code,
                score: overview.awayGoals
            ),
            period: overview.time.period,
            periodTime: overview.time.periodTime,
            periodEnd: overview.time.periodEnd,
            state: translateGameState(overview.state)
        )
    }

    private func translateGameState(_ state: GameData.GameState) -> LiveGameUpdate.GameState {
        switch state {
        case .notStarted:
            return .notStarted
        case .ongoing:
            return .ongoing
        case .periodBreak:
            return .periodBreak
        case .overtime:
            return .overtime
        case .gameEnded:
            return .gameEnded
        }
    }

    // MARK: - Continuation Management

    private func addContinuation(_ id: UUID, continuation: AsyncStream<LiveGameUpdate>.Continuation) {
        continuations[id] = continuation

        // Send cached data immediately to new subscribers
        for update in cache.values {
            continuation.yield(update)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)

        // If no more subscribers, disconnect
        if continuations.isEmpty {
            disconnect()
        }
    }
}

// MARK: - SSE Buffer

/// Thread-safe buffer for accumulating SSE event data
private actor SSEBuffer {
    private var data = Data()

    func append(_ newData: Data) {
        data.append(newData)
    }

    func extractEvent() -> String? {
        // SSE events are separated by double newlines
        guard let eventData = data.range(of: "\n\n".data(using: .utf8)!) else {
            return nil
        }

        let eventBytes = data[..<eventData.lowerBound]
        data.removeSubrange(..<eventData.upperBound)

        return String(data: eventBytes, encoding: .utf8)
    }
}

// MARK: - URLSession Delegate

private class SSEDelegate: NSObject, URLSessionDataDelegate {
    private let onData: (Data) async -> Void
    private let onComplete: (Error?) async -> Void

    init(onData: @escaping (Data) async -> Void, onComplete: @escaping (Error?) async -> Void) {
        self.onData = onData
        self.onComplete = onComplete
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Task {
            await onData(data)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task {
            await onComplete(error)
        }
    }
}

// MARK: - GameData Models (fileprivate - unstable external API)

fileprivate struct GameData: Codable {
    let gameOverview: GameOverview

    struct GameOverview: Codable {
        let gameId: Int?
        let gameUuid: String
        let homeTeam: TeamData
        let awayTeam: TeamData
        let homeGoals: Int
        let awayGoals: Int
        let state: GameState
        let time: GameTime
    }

    struct TeamData: Codable {
        let code: String
    }

    struct GameTime: Codable {
        let period: Int
        let periodTime: Int
        let periodEnd: Int
    }

    enum GameState: String, Codable {
        case notStarted = "NotStarted"
        case ongoing = "Ongoing"
        case periodBreak = "PeriodBreak"
        case overtime = "Overtime"
        case gameEnded = "GameEnded"
    }
}
