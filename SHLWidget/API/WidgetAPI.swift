//
//  WidgetAPI.swift
//  SHLWidget
//
//  Cache-first API client for widgets with background refresh
//

import Foundation

class WidgetAPI {
    private let cache = WidgetDataCache.shared
    private let backgroundManager = BackgroundSessionManager.shared

    // Cache max ages in seconds
    private let matchesCacheMaxAge: TimeInterval = 5 * 60      // 5 minutes
    private let standingsCacheMaxAge: TimeInterval = 30 * 60   // 30 minutes
    private let teamMatchesCacheMaxAge: TimeInterval = 10 * 60 // 10 minutes

    init() {}

    // MARK: - Latest Matches

    /// Returns cached matches, triggering background refresh if stale
    /// - Parameter forceRefresh: Force a background refresh even if cache is fresh
    /// - Returns: Cached matches or nil if no cache exists
    func getLatestMatches(forceRefresh: Bool = false) -> [WidgetGame]? {
        let cacheKey = WidgetDataCache.CacheKey.latestMatches

        // Check if we have fresh cache
        if !forceRefresh && cache.isFresh(for: cacheKey, maxAge: matchesCacheMaxAge) {
            return cache.load(for: cacheKey)
        }

        // Trigger background download
        backgroundManager.startDownload(type: .latestMatches)

        // Return stale cache if available (better than nothing)
        return cache.load(for: cacheKey)
    }

    // MARK: - Team Matches

    /// Returns cached team matches, triggering background refresh if stale
    /// - Parameters:
    ///   - teamCode: The team code (e.g., "LHF")
    ///   - forceRefresh: Force a background refresh even if cache is fresh
    /// - Returns: Cached matches or nil if no cache exists
    func getTeamMatches(teamCode: String, forceRefresh: Bool = false) -> [WidgetGame]? {
        let cacheKey = WidgetDataCache.CacheKey.teamMatches(teamCode)

        // Check if we have fresh cache
        if !forceRefresh && cache.isFresh(for: cacheKey, maxAge: teamMatchesCacheMaxAge) {
            return cache.load(for: cacheKey)
        }

        // Trigger background download
        backgroundManager.startDownload(type: .teamMatches, teamCode: teamCode)

        // Return stale cache if available
        return cache.load(for: cacheKey)
    }

    // MARK: - Standings

    /// Returns cached standings, triggering background refresh if stale
    /// - Parameter forceRefresh: Force a background refresh even if cache is fresh
    /// - Returns: Cached standings or nil if no cache exists
    func getStandings(forceRefresh: Bool = false) -> [WidgetStanding]? {
        let cacheKey = WidgetDataCache.CacheKey.standings

        // Check if we have fresh cache
        if !forceRefresh && cache.isFresh(for: cacheKey, maxAge: standingsCacheMaxAge) {
            return cache.load(for: cacheKey)
        }

        // Trigger background download
        backgroundManager.startDownload(type: .standings)

        // Return stale cache if available
        return cache.load(for: cacheKey)
    }

    // MARK: - Cache Info

    /// Check if data exists in cache (regardless of freshness)
    func hasCachedMatches() -> Bool {
        let matches: [WidgetGame]? = cache.load(for: .latestMatches)
        return matches != nil && !(matches?.isEmpty ?? true)
    }

    func hasCachedStandings() -> Bool {
        let standings: [WidgetStanding]? = cache.load(for: .standings)
        return standings != nil && !(standings?.isEmpty ?? true)
    }

    func hasCachedTeamMatches(teamCode: String) -> Bool {
        let matches: [WidgetGame]? = cache.load(for: WidgetDataCache.CacheKey.teamMatches(teamCode))
        return matches != nil && !(matches?.isEmpty ?? true)
    }
}
