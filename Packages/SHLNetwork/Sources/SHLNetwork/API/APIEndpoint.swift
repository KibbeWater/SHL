//
//  APIEndpoint.swift
//  SHLNetwork
//
//  Created by Claude Code
//

import Foundation

public struct APIEndpoint: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]?

    public enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    public init(path: String, method: HTTPMethod = .get, queryItems: [URLQueryItem]? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

// MARK: - Match Endpoints

extension APIEndpoint {
    public static func latestMatches(page: Int, limit: Int) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/matches",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        )
    }

    public static func searchMatches(
        date: String? = nil,
        team: String? = nil,
        season: String? = nil,
        state: String? = nil,
        descending: Bool? = nil,
        page: Int,
        limit: Int
    ) -> APIEndpoint {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: descending == true ? "desc" : "asc"),
        ]
        if let date {
            items.append(URLQueryItem(name: "date", value: date))
        }
        if let team {
            items.append(URLQueryItem(name: "team", value: team))
        }
        if let season {
            items.append(URLQueryItem(name: "season", value: season))
        }
        if let state {
            items.append(URLQueryItem(name: "state", value: state))
        }
        return APIEndpoint(path: "/api/v1/matches", queryItems: items)
    }

    public static var liveMatches: APIEndpoint {
        APIEndpoint(path: "/api/v1/matches/live")
    }

    public static func getLiveMatch(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/live/\(id)")
    }

    public static func matchDetail(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/matches/\(id)")
    }

    public static func matchStats(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/matches/\(id)/stats")
    }

    public static func matchEvents(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/matches/\(id)/events")
    }

    public static func seasonMatches(seasonCode: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/matches/season/\(seasonCode)")
    }

    public static func recentMatches(limit: Int = 10) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/matches/recent",
            queryItems: [
                URLQueryItem(name: "upcoming", value: String(limit)),
            ]
        )
    }
}

// MARK: - Team Endpoints

extension APIEndpoint {
    public static var teams: APIEndpoint {
        APIEndpoint(path: "/api/v1/teams")
    }

    public static func teamDetail(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/teams/\(id)")
    }

    public static func teamRoster(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/teams/\(id)/roster")
    }

    public static func teamMatches(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/teams/\(id)/matches")
    }
}

// MARK: - Player Endpoints

extension APIEndpoint {
    public static func playerDetail(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/players/\(id)")
    }

    public static func playerStats(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/players/\(id)/stats")
    }
}

// MARK: - Season/League Endpoints

extension APIEndpoint {
    public static var currentSeason: APIEndpoint {
        APIEndpoint(path: "/api/v1/seasons/current")
    }

    public static var currentSeasonInfo: APIEndpoint {
        APIEndpoint(path: "/api/v1/seasons/current/info")
    }

    public static var allSeasons: APIEndpoint {
        APIEndpoint(path: "/api/v1/seasons")
    }

    public static func standings(seasonId: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/standings/\(seasonId)")
    }

    public static var currentStandings: APIEndpoint {
        APIEndpoint(path: "/api/v1/standings")
    }
}
