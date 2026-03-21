//
//  SharedTeamColorCache.swift
//  SHL
//
//  Shared team color cache stored in App Group for widget access
//

#if os(iOS)
import SwiftUI
import UIKit

/// Stores team colors in the App Group container so widgets can access them
public class SharedTeamColorCache {
    public static let shared = SharedTeamColorCache()

    private let fileManager = FileManager.default
    private let appGroupID = SharedPreferenceKeys.groupIdentifier
    private let fileName = "TeamColors.json"

    private var memoryCache: [String: CachedColor] = [:]

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

        init(color: UIColor) {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(a)
        }

        var uiColor: UIColor {
            UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }

        var color: Color {
            Color(uiColor: uiColor)
        }
    }

    // MARK: - Public API

    /// Cache a color for a team code
    public func cacheColor(_ color: UIColor, forTeamCode teamCode: String) {
        let cached = CachedColor(color: color)
        memoryCache[teamCode.uppercased()] = cached
        saveToDisk()
    }

    /// Cache a color for a team code (SwiftUI Color)
    public func cacheColor(_ color: Color, forTeamCode teamCode: String) {
        cacheColor(UIColor(color), forTeamCode: teamCode)
    }

    /// Get cached color for a team code
    public func getColor(forTeamCode teamCode: String) -> Color? {
        memoryCache[teamCode.uppercased()]?.color
    }

    /// Get cached UIColor for a team code
    public func getUIColor(forTeamCode teamCode: String) -> UIColor? {
        memoryCache[teamCode.uppercased()]?.uiColor
    }

    /// Check if a team has a cached color
    public func hasColor(forTeamCode teamCode: String) -> Bool {
        memoryCache[teamCode.uppercased()] != nil
    }

    /// Get all cached team codes
    public var cachedTeamCodes: [String] {
        Array(memoryCache.keys)
    }

    // MARK: - Persistence

    private func saveToDisk() {
        guard let fileURL = cacheFileURL else { return }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(memoryCache)
            try data.write(to: fileURL)
        } catch {
            print("SharedTeamColorCache: Failed to save: \(error)")
        }
    }

    private func loadFromDisk() {
        guard let fileURL = cacheFileURL,
              fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            memoryCache = try decoder.decode([String: CachedColor].self, from: data)
        } catch {
            print("SharedTeamColorCache: Failed to load: \(error)")
        }
    }

    /// Force reload from disk (useful for widgets)
    public func reloadFromDisk() {
        loadFromDisk()
    }
}
#endif
