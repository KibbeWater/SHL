//
//  FeaturedGameAlgo.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation

/// Algorithm for selecting the most relevant featured game from a list of matches
class FeaturedGameAlgo {
    /// Get the most relevant featured game from a list of matches
    /// - Parameters:
    ///   - matches: Array of matches to score
    ///   - interestedTeams: Array of team UUIDs for bonus scoring
    ///   - favoriteTeamId: Optional favorite team UUID for higher priority scoring
    /// - Returns: The highest-scored match, or nil if no matches provided
    static func getFeaturedGame(_ matches: [Match], interestedTeams: [String], favoriteTeamId: String? = nil) async -> Match? {
        let scoredMatches = await scoreAndSortMatches(matches, interestedTeams: interestedTeams, favoriteTeamId: favoriteTeamId)
        return scoredMatches.first?.0
    }

    /// Get team by team code
    /// - Parameter code: Team code (e.g., "FHC", "LHF")
    /// - Returns: Team object if found, nil otherwise
    static func getTeamByCode(_ code: String) async -> Team? {
        guard let teams = try? await SHLAPIClient.shared.getTeams() else { return nil }
        return teams.first(where: { $0.code == code })
    }

    /// Score and sort matches by relevance
    /// - Parameters:
    ///   - matches: Array of matches to score
    ///   - interestedTeams: Array of team UUIDs for bonus scoring
    ///   - favoriteTeamId: Optional favorite team UUID for higher priority scoring
    /// - Returns: Array of tuples containing match and score, sorted by score (highest first)
    private static func scoreAndSortMatches(_ matches: [Match], interestedTeams: [String], favoriteTeamId: String? = nil) async -> [(Match, Double)] {
        // First, asynchronously get all team UUIDs
        let teamUUIDs = await withTaskGroup(of: (String, String).self) { group in
            for match in matches {
                group.addTask {
                    let homeTeam = await self.getTeamByCode(match.homeTeam.code)
                    return (match.homeTeam.code, homeTeam?.id ?? "")
                }
                group.addTask {
                    let awayTeam = await self.getTeamByCode(match.awayTeam.code)
                    return (match.awayTeam.code, awayTeam?.id ?? "")
                }
            }

            var uuidDict = [String: String]()
            for await (code, uuid) in group {
                uuidDict[code] = uuid
            }
            return uuidDict
        }

        // Now score the matches
        let scoredMatches = matches.map { game -> (Match, Double) in
            var score: Double = 0

            // Live games get the highest base score
            if game.isLive() {
                score += 1000
            }

            // Favorite team bonus (higher priority than interested teams)
            if let favoriteTeamId = favoriteTeamId,
               let homeTeamUUID = teamUUIDs[game.homeTeam.code],
               let awayTeamUUID = teamUUIDs[game.awayTeam.code]
            {
                if homeTeamUUID == favoriteTeamId || awayTeamUUID == favoriteTeamId {
                    score += 750
                }
            }

            // Interested teams bonus
            if !interestedTeams.isEmpty,
               let homeTeamUUID = teamUUIDs[game.homeTeam.code],
               let awayTeamUUID = teamUUIDs[game.awayTeam.code]
            {
                if interestedTeams.contains(homeTeamUUID) || interestedTeams.contains(awayTeamUUID) {
                    score += 500
                }
            }

            // Upcoming games score
            if !game.played {
                let timeUntilGame = game.date.timeIntervalSinceNow
                if timeUntilGame > 0 {
                    score += max(100 - log10(timeUntilGame / 3600) * 20, 0)
                }
            } else {
                // Played games score
                let timeSinceGame = -game.date.timeIntervalSinceNow
                score += max(50 - log10(timeSinceGame / 3600) * 10, 0)
            }

            return (game, score)
        }

        // Sort the matches based on their scores, highest to lowest
        return scoredMatches.sorted { $0.1 > $1.1 }
    }
}
