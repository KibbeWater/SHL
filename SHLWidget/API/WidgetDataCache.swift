//
//  WidgetDataCache.swift
//  SHLWidget
//
//  Persistent file-based cache for widget data in App Group container
//

import Foundation

class WidgetDataCache {
    static let shared = WidgetDataCache()

    private let fileManager = FileManager.default
    private let appGroupID = "group.kibbewater.shl"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        createCacheDirectoryIfNeeded()
    }

    // MARK: - Cache Directory

    private var cacheDirectory: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("WidgetCache", isDirectory: true)
    }

    private func createCacheDirectoryIfNeeded() {
        guard let cacheDir = cacheDirectory else { return }
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Cache Keys

    enum CacheKey: String {
        case latestMatches
        case standings

        // For team-specific cache, use teamMatches(teamCode:)
        static func teamMatches(_ teamCode: String) -> String {
            "teamMatches_\(teamCode)"
        }
    }

    // MARK: - Save/Load Operations

    func save<T: Encodable>(_ data: T, for key: String) {
        guard let cacheDir = cacheDirectory else { return }

        let fileURL = cacheDir.appendingPathComponent("\(key).json")
        let metaURL = cacheDir.appendingPathComponent("\(key).meta")

        do {
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: fileURL)

            // Save timestamp metadata
            let meta = CacheMetadata(timestamp: Date())
            let metaData = try encoder.encode(meta)
            try metaData.write(to: metaURL)
        } catch {
            print("WidgetDataCache: Failed to save \(key): \(error)")
        }
    }

    func save<T: Encodable>(_ data: T, for key: CacheKey) {
        save(data, for: key.rawValue)
    }

    func load<T: Decodable>(for key: String) -> T? {
        guard let cacheDir = cacheDirectory else { return nil }

        let fileURL = cacheDir.appendingPathComponent("\(key).json")

        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("WidgetDataCache: Failed to load \(key): \(error)")
            return nil
        }
    }

    func load<T: Decodable>(for key: CacheKey) -> T? {
        load(for: key.rawValue)
    }

    // MARK: - Freshness Check

    func isFresh(for key: String, maxAge: TimeInterval) -> Bool {
        guard let cacheDir = cacheDirectory else { return false }

        let metaURL = cacheDir.appendingPathComponent("\(key).meta")

        guard fileManager.fileExists(atPath: metaURL.path) else { return false }

        do {
            let metaData = try Data(contentsOf: metaURL)
            let meta = try decoder.decode(CacheMetadata.self, from: metaData)
            return Date().timeIntervalSince(meta.timestamp) < maxAge
        } catch {
            return false
        }
    }

    func isFresh(for key: CacheKey, maxAge: TimeInterval) -> Bool {
        isFresh(for: key.rawValue, maxAge: maxAge)
    }

    // MARK: - Cache Age

    func cacheAge(for key: String) -> TimeInterval? {
        guard let cacheDir = cacheDirectory else { return nil }

        let metaURL = cacheDir.appendingPathComponent("\(key).meta")

        guard fileManager.fileExists(atPath: metaURL.path) else { return nil }

        do {
            let metaData = try Data(contentsOf: metaURL)
            let meta = try decoder.decode(CacheMetadata.self, from: metaData)
            return Date().timeIntervalSince(meta.timestamp)
        } catch {
            return nil
        }
    }

    // MARK: - Clear Cache

    func clear(for key: String) {
        guard let cacheDir = cacheDirectory else { return }

        let fileURL = cacheDir.appendingPathComponent("\(key).json")
        let metaURL = cacheDir.appendingPathComponent("\(key).meta")

        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: metaURL)
    }

    func clearAll() {
        guard let cacheDir = cacheDirectory else { return }
        try? fileManager.removeItem(at: cacheDir)
        createCacheDirectoryIfNeeded()
    }
}

// MARK: - Cache Metadata

private struct CacheMetadata: Codable {
    let timestamp: Date
}
