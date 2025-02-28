//
//  FeaturedGameAlgo.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 23/10/24.
//

import Foundation
import HockeyKit

class FeaturedGameAlgo {
    static func GetFeaturedGame(_ api: HockeyAPI, matches: [Game]) async -> Game? {
        let scoredMatches = await scoreAndSortHockeyMatches(
            api,
            matches: matches,
            preferredTeam: Settings.shared.getPreferredTeam()
        )
        return scoredMatches.first?.0
    }
    
    static func getTeamByCode(_ api: HockeyAPI, code: String) async -> SiteTeam? {
        guard let teams = try? await api.team.getTeams() else { return nil }
        return teams.first(where: { $0.teamNames.code == code })
    }
    
    private static func scoreAndSortHockeyMatches(_ api: HockeyAPI, matches: [Game], preferredTeam: String?) async -> [(Game, Double)] {
        // First, asynchronously get all team UUIDs
        let teamUUIDs = await withTaskGroup(of: (String, String).self) { group in
            for match in matches {
                group.addTask {
                    let homeTeam = await self.getTeamByCode(api, code: match.homeTeam.code)
                    return (match.homeTeam.code, homeTeam?.id ?? "")
                }
                group.addTask {
                    let awayTeam = await self.getTeamByCode(api, code: match.awayTeam.code)
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
        let scoredMatches = matches.map { game -> (Game, Double) in
            var score: Double = 0
            
            // Live games get the highest base score
            if game.isLive() {
                score += 1000
            }
            
            // Preferred team bonus
            if let preferredTeam = preferredTeam,
               let homeTeamUUID = teamUUIDs[game.homeTeam.code],
               let awayTeamUUID = teamUUIDs[game.awayTeam.code] {
                if homeTeamUUID == preferredTeam || awayTeamUUID == preferredTeam {
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
