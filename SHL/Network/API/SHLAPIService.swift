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
    case latestMatches
    case matchDetail(id: String)
    case matchStats(id: String)
    case matchPBP(id: String)
    case schedule(seasonId: String, seriesId: String, teamIds: [String]?)

    // Team endpoints
    case teams
    case teamDetail(id: String)
    case teamLineup(id: String)

    // Player endpoints
    case playerDetail(id: String)
    case playerGameLog(id: String)

    // Season/League endpoints
    case currentSeason
    case currentSsgt
    case standings(ssgtUuid: String)
    case currentSeries
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
        case .latestMatches:
            return "/api/matches/latest"
        case .matchDetail(let id):
            return "/api/matches/\(id)"
        case .matchStats(let id):
            return "/api/matches/\(id)/stats"
        case .matchPBP(let id):
            return "/api/matches/\(id)/pbp"
        case .schedule:
            return "/api/matches/schedule"

        // Team paths
        case .teams:
            return "/api/teams"
        case .teamDetail(let id):
            return "/api/teams/\(id)"
        case .teamLineup(let id):
            return "/api/teams/\(id)/lineup"

        // Player paths
        case .playerDetail(let id):
            return "/api/players/\(id)"
        case .playerGameLog(let id):
            return "/api/players/\(id)/gamelog"

        // Season/League paths
        case .currentSeason:
            return "/api/seasons/current"
        case .currentSsgt:
            return "/api/seasons/current/ssgt"
        case .standings(let ssgtUuid):
            return "/api/standings/\(ssgtUuid)"
        case .currentSeries:
            return "/api/series/current"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case .schedule(let seasonId, let seriesId, let teamIds):
            var params: [String: Any] = [
                "seasonId": seasonId,
                "seriesId": seriesId
            ]
            if let teamIds = teamIds, !teamIds.isEmpty {
                params["teamIds"] = teamIds
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        default:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    var sampleData: Data {
        return Data()
    }
}
