//
//  SHLAPIService.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
import Moya

enum SHLAPIService {
    // Match endpoints
    case latestMatches(page: Int, limit: Int)
    case searchMatches(date: String?, team: String?, season: String?, state: String?, descending: Bool?, page: Int, limit: Int)
    case liveMatches
    case getLiveMatch(id: String)
    case matchDetail(id: String)
    case matchStats(id: String)
    case matchEvents(id: String)
    case seasonMatches(seasonCode: String)
    case recentMatches(limit: Int = 10)

    // Team endpoints
    case teams
    case teamDetail(id: String)
    case teamRoster(id: String)
    case teamMatches(id: String)

    // Player endpoints
    case playerDetail(id: String)
    case playerStats(id: String)

    // Season/League endpoints
    case currentSeason
    case currentSeasonInfo
    case allSeasons
    case standings(seasonId: String)
    case currentStandings
}

extension SHLAPIService: TargetType {
    var baseURL: URL {
        // Use environment variable or default to production
        let urlString = ProcessInfo.processInfo.environment["SHL_API_BASE_URL"] ?? "https://api.lrlnet.se"
        return URL(string: urlString)!
    }

    var path: String {
        switch self {
        // Match paths
        case .latestMatches, .searchMatches:
            return "/api/v1/matches"
        case .liveMatches:
            return "/api/v1/matches/live"
        case let .getLiveMatch(id):
            return "/api/v1/live/\(id)"
        case let .matchDetail(id):
            return "/api/v1/matches/\(id)"
        case let .matchStats(id):
            return "/api/v1/matches/\(id)/stats"
        case let .matchEvents(id):
            return "/api/v1/matches/\(id)/events"
        case let .seasonMatches(seasonCode):
            return "/api/v1/matches/season/\(seasonCode)"
        case .recentMatches:
            return "/api/v1/matches/recent"
        // Team paths
        case .teams:
            return "/api/v1/teams"
        case let .teamDetail(id):
            return "/api/v1/teams/\(id)"
        case let .teamRoster(id):
            return "/api/v1/teams/\(id)/roster"
        case let .teamMatches(id):
            return "/api/v1/teams/\(id)/matches"
        // Player paths
        case let .playerDetail(id):
            return "/api/v1/players/\(id)"
        case let .playerStats(id):
            return "/api/v1/players/\(id)/stats"
        // Season/League paths
        case .currentSeason:
            return "/api/v1/seasons/current"
        case .currentSeasonInfo:
            return "/api/v1/seasons/current/info"
        case .allSeasons:
            return "/api/v1/seasons"
        case let .standings(seasonId):
            return "/api/v1/standings/\(seasonId)"
        case .currentStandings:
            return "/api/v1/standings"
        }
    }

    var method: Moya.Method {
        switch self {
        default:
            return .get
        }
    }

    var task: Task {
        switch self {
        case let .latestMatches(page, limit):
            return .requestParameters(
                parameters: ["page": page, "limit": limit],
                encoding: URLEncoding.queryString
            )
        case let .searchMatches(date, team, season, state, descending, page, limit):
            var parameters: [String: Any] = ["page": page, "limit": limit, "sort": descending == true ? "desc" : "asc"]
            if let date = date {
                parameters["date"] = date
            }
            if let team = team {
                parameters["team"] = team
            }
            if let season = season {
                parameters["season"] = season
            }
            if let state = state {
                parameters["state"] = state
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )
        case let .recentMatches(limit):
            return .requestParameters(parameters: ["upcoming": limit], encoding: URLEncoding.queryString)
        default:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }

    var sampleData: Data {
        return Data()
    }
}
