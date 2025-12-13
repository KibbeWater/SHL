//
//  BackgroundSessionManager.swift
//  SHLWidget
//
//  Manages background URLSession for widget network requests
//  Ensures downloads complete even if widget extension is suspended
//

import Foundation
import WidgetKit

class BackgroundSessionManager: NSObject {
    static let shared = BackgroundSessionManager()

    private let sessionIdentifier = "com.kibbewater.shl.widget.background"
    private let cache = WidgetDataCache.shared
    private let decoder: JSONDecoder

    private let baseURL = "https://api.lrlnet.se"

    // MARK: - Thread-safe completion handler

    private let handlerQueue = DispatchQueue(label: "com.kibbewater.shl.background.handler")
    private var _backgroundCompletionHandler: (() -> Void)?
    private var backgroundCompletionHandler: (() -> Void)? {
        get { handlerQueue.sync { _backgroundCompletionHandler } }
        set { handlerQueue.sync { _backgroundCompletionHandler = newValue } }
    }

    // MARK: - Download Types

    enum DownloadType: String {
        case latestMatches = "matches"
        case standings = "standings"
        case teamMatches = "team_matches"

        var cacheKey: String {
            switch self {
            case .latestMatches: return WidgetDataCache.CacheKey.latestMatches.rawValue
            case .standings: return WidgetDataCache.CacheKey.standings.rawValue
            case .teamMatches: return "" // Set dynamically via taskDescription
            }
        }

        var widgetKind: String {
            switch self {
            case .latestMatches: return "SHLWidgetUpcoming"
            case .standings: return "SHLWidgetStandings"
            case .teamMatches: return "SHLWidgetTeamSchedule"
            }
        }
    }

    // MARK: - Initialization

    private override init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        super.init()
    }

    // MARK: - Background Session

    lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // MARK: - Background Events Handler

    /// Called from onBackgroundURLSessionEvents modifier
    /// Returns true if this manager handles the identifier
    func handleBackgroundEvents(identifier: String, completion: @escaping () -> Void) -> Bool {
        guard identifier == sessionIdentifier else { return false }
        backgroundCompletionHandler = completion
        // Re-attach to the session to receive pending events
        _ = backgroundSession
        return true
    }

    // MARK: - Start Downloads

    func startDownload(type: DownloadType, teamCode: String? = nil) {
        let url: URL?

        switch type {
        case .latestMatches:
            url = URL(string: "\(baseURL)/api/v1/matches/recent?upcoming=10")
        case .standings:
            url = URL(string: "\(baseURL)/api/v1/standings")
        case .teamMatches:
            guard let code = teamCode else { return }
            // Use search endpoint with team filter - returns PaginatedResponse
            url = URL(string: "\(baseURL)/api/v1/matches?team=\(code)&state=scheduled&limit=10")
        }

        guard let downloadURL = url else { return }

        // Check if there's already a pending download for this type
        backgroundSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            let existingTask = downloadTasks.first { task in
                task.taskDescription?.hasPrefix(type.rawValue) == true
            }

            if existingTask == nil {
                let task = self.backgroundSession.downloadTask(with: downloadURL)
                // Store type and optional team code in taskDescription
                if let code = teamCode {
                    task.taskDescription = "\(type.rawValue)|\(code)"
                } else {
                    task.taskDescription = type.rawValue
                }
                task.resume()
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundSessionManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskDescription = downloadTask.taskDescription else { return }

        // Parse task description (format: "type" or "type|teamCode")
        let parts = taskDescription.split(separator: "|")
        guard let typeString = parts.first,
              let type = DownloadType(rawValue: String(typeString)) else { return }

        let teamCode = parts.count > 1 ? String(parts[1]) : nil

        do {
            let data = try Data(contentsOf: location)
            try processDownloadedData(data, type: type, teamCode: teamCode)

            // Reload the appropriate widget timeline
            WidgetCenter.shared.reloadTimelines(ofKind: type.widgetKind)

        } catch {
            print("BackgroundSessionManager: Failed to process download: \(error)")
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("BackgroundSessionManager: Download failed: \(error)")
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }

    // MARK: - Process Downloaded Data

    private func processDownloadedData(_ data: Data, type: DownloadType, teamCode: String?) throws {
        switch type {
        case .latestMatches:
            // API returns RecentMatchesResponse: { upcoming: [...], recent: [...] }
            let response = try decoder.decode(RecentMatchesResponse.self, from: data)
            let games = response.upcoming.map { $0.toWidgetGame() }
            cache.save(games, for: .latestMatches)

        case .standings:
            // API returns direct array [Standings]
            let standings = try decoder.decode([Standings].self, from: data)
            let widgetStandings = standings.map { $0.toWidgetStanding() }
            cache.save(widgetStandings, for: .standings)

        case .teamMatches:
            guard let code = teamCode else { return }
            // API returns PaginatedResponse: { data: [...], page, limit }
            let response = try decoder.decode(PaginatedResponse<Match>.self, from: data)
            let games = response.data.map { $0.toWidgetGame() }
            cache.save(games, for: WidgetDataCache.CacheKey.teamMatches(code))
        }
    }
}

// MARK: - Model Extensions for Widget Conversion

extension Match {
    func toWidgetGame() -> WidgetGame {
        WidgetGame(
            id: id,
            date: date,
            venue: venue ?? "Unknown",
            homeTeam: WidgetTeam(name: homeTeam.name, code: homeTeam.code),
            awayTeam: WidgetTeam(name: awayTeam.name, code: awayTeam.code),
            homeScore: homeScore,
            awayScore: awayScore
        )
    }
}

extension Standings {
    func toWidgetStanding() -> WidgetStanding {
        WidgetStanding(
            id: id,
            rank: rank,
            team: WidgetTeam(name: team.name, code: team.code),
            points: points,
            gamesPlayed: gamesPlayed,
            goalDifference: goalDifference,
            wins: wins,
            losses: losses,
            overtimeLosses: overtimeLosses
        )
    }
}
