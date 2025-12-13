//
//  WidgetSharedColorCache.swift
//  SHLWidget
//
//  Reads team colors from shared App Group cache populated by main app
//

import SwiftUI

/// Reads team colors from the App Group container (populated by main app)
class WidgetSharedColorCache {
    static let shared = WidgetSharedColorCache()

    private let fileManager = FileManager.default
    private let appGroupID = "group.kibbewater.shl"
    private let fileName = "TeamColors.json"

    private var memoryCache: [String: CachedColor] = [:]
    private var hasLoaded = false

    private init() {
        loadFromDisk()
    }

    // MARK: - Cache File Location

    private var cacheFileURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    // MARK: - Color Storage Model

    private struct CachedColor: Codable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        var color: Color {
            Color(red: red, green: green, blue: blue, opacity: alpha)
        }
    }

    // MARK: - Public API

    /// Get cached color for a team code
    func getColor(forTeamCode teamCode: String) -> Color? {
        // Reload if not loaded yet
        if !hasLoaded {
            loadFromDisk()
        }
        return memoryCache[teamCode.uppercased()]?.color
    }

    /// Check if a team has a cached color
    func hasColor(forTeamCode teamCode: String) -> Bool {
        if !hasLoaded {
            loadFromDisk()
        }
        return memoryCache[teamCode.uppercased()] != nil
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let fileURL = cacheFileURL,
              fileManager.fileExists(atPath: fileURL.path) else {
            hasLoaded = true
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            memoryCache = try decoder.decode([String: CachedColor].self, from: data)
            hasLoaded = true
        } catch {
            print("WidgetSharedColorCache: Failed to load: \(error)")
            hasLoaded = true
        }
    }

    /// Force reload from disk
    func reloadFromDisk() {
        hasLoaded = false
        loadFromDisk()
    }
}
