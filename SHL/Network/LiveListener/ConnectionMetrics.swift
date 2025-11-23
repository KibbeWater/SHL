//
//  ConnectionMetrics.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation
import PostHog

/// Tracks connection quality metrics and health for the live listener
public class ConnectionMetrics: ObservableObject {
    /// Connection health status
    public enum HealthStatus: String, Sendable {
        case excellent      // Connected, low latency, no recent errors
        case good          // Connected, normal latency, occasional errors
        case poor          // Connected but unstable (frequent reconnects)
        case disconnected  // Not connected
    }

    // MARK: - Published Properties

    @Published public private(set) var healthStatus: HealthStatus = .disconnected
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var lastDataReceivedAt: Date?
    @Published public private(set) var connectionAttempts: Int = 0
    @Published public private(set) var reconnectionCount: Int = 0
    @Published public private(set) var errorCount: Int = 0

    // MARK: - Private Properties

    private var connectedAt: Date?
    private var lastReconnectAt: Date?
    private var recentErrors: [Date] = []
    private let errorWindow: TimeInterval = 60 // Track errors in last 60 seconds

    // MARK: - Connection Events

    @MainActor
    public func recordConnectionAttempt() {
        connectionAttempts += 1
    }

    @MainActor
    public func recordConnectionSuccess() {
        isConnected = true
        connectedAt = Date()

        if reconnectionCount > 0 {
            lastReconnectAt = Date()
            logToPostHog(event: "live_listener_reconnected", properties: [
                "reconnection_count": reconnectionCount,
                "total_attempts": connectionAttempts
            ])
        } else {
            logToPostHog(event: "live_listener_connected", properties: [
                "total_attempts": connectionAttempts
            ])
        }

        updateHealthStatus()
    }

    @MainActor
    public func recordReconnection() {
        reconnectionCount += 1
        updateHealthStatus()
    }

    @MainActor
    public func recordDisconnection() {
        isConnected = false
        connectedAt = nil
        healthStatus = .disconnected

        logToPostHog(event: "live_listener_disconnected", properties: [
            "reconnection_count": reconnectionCount,
            "uptime_seconds": getUptimeSeconds()
        ])
    }

    @MainActor
    public func recordDataReceived() {
        lastDataReceivedAt = Date()
        updateHealthStatus()
    }

    @MainActor
    public func recordError(_ error: Error) {
        errorCount += 1
        recentErrors.append(Date())
        cleanupOldErrors()

        logToPostHog(event: "live_listener_error", properties: [
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription,
            "recent_error_count": recentErrors.count,
            "is_connected": isConnected
        ])

        updateHealthStatus()
    }

    // MARK: - Metrics Calculation

    /// Get current data staleness in seconds
    public func getDataStaleness() -> TimeInterval? {
        guard let lastReceived = lastDataReceivedAt else { return nil }
        return Date().timeIntervalSince(lastReceived)
    }

    /// Get connection uptime in seconds
    public func getUptimeSeconds() -> TimeInterval? {
        guard let connected = connectedAt else { return nil }
        return Date().timeIntervalSince(connected)
    }

    /// Get average time between reconnections
    public func getReconnectionFrequency() -> TimeInterval? {
        guard reconnectionCount > 0,
              let uptime = getUptimeSeconds() else { return nil }
        return uptime / Double(reconnectionCount)
    }

    // MARK: - Health Status

    private func updateHealthStatus() {
        guard isConnected else {
            healthStatus = .disconnected
            return
        }

        let staleness = getDataStaleness() ?? 0
        let errorRate = Double(recentErrors.count) / errorWindow

        // Excellent: Fresh data, no recent errors, stable connection
        if staleness < 5 && recentErrors.isEmpty && reconnectionCount < 2 {
            healthStatus = .excellent
        }
        // Good: Reasonably fresh data, few errors
        else if staleness < 15 && errorRate < 0.1 && reconnectionCount < 5 {
            healthStatus = .good
        }
        // Poor: Stale data or frequent errors/reconnections
        else if staleness < 30 || errorRate < 0.3 || reconnectionCount < 10 {
            healthStatus = .poor
        }
        // Disconnected: Very stale data
        else {
            healthStatus = .disconnected
        }
    }

    private func cleanupOldErrors() {
        let cutoff = Date().addingTimeInterval(-errorWindow)
        recentErrors.removeAll { $0 < cutoff }
    }

    // MARK: - Analytics

    private func logToPostHog(event: String, properties: [String: Any] = [:]) {
        #if !DEBUG
        var enrichedProperties = properties
        enrichedProperties["health_status"] = healthStatus.rawValue
        enrichedProperties["connection_attempts"] = connectionAttempts
        enrichedProperties["reconnection_count"] = reconnectionCount
        enrichedProperties["error_count"] = errorCount

        if let staleness = getDataStaleness() {
            enrichedProperties["data_staleness_seconds"] = staleness
        }

        if let uptime = getUptimeSeconds() {
            enrichedProperties["uptime_seconds"] = uptime
        }

        PostHogSDK.shared.capture(event, properties: enrichedProperties)
        #endif
    }

    /// Log periodic statistics snapshot to PostHog
    @MainActor
    public func logStatistics() {
        logToPostHog(event: "live_listener_statistics", properties: [
            "recent_errors": recentErrors.count
        ])
    }

    // MARK: - Reset

    @MainActor
    public func reset() {
        healthStatus = .disconnected
        isConnected = false
        lastDataReceivedAt = nil
        connectionAttempts = 0
        reconnectionCount = 0
        errorCount = 0
        connectedAt = nil
        lastReconnectAt = nil
        recentErrors.removeAll()
    }
}
