//
//  CurrentSeason.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 28/10/25.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
struct CurrentSeasonTool: Tool {
    let name: String = "Get Season Information"
    var description: String = """
    Retrieves information about the current active SHL season. Returns the season year/code and a complete list of all \
    participating teams with their names, team codes (abbreviations like 'LHF', 'RBK'), and IDs. \
    IMPORTANT: Call this tool FIRST when users ask about teams or matches - the team codes returned here are REQUIRED \
    for filtering matches by team in the Match Search tool.
    """

    @Generable
    struct Arguments {
        // No arguments required - this tool retrieves current season data directly
    }

    func call(arguments: Arguments) async throws -> String {
        let resp = try await SHLAPIClient.shared.getCurrentSeasonInfo()

        let teamsList = resp.teams.map { team in
            "  - \(team.name) (Code: \(team.code), ID: \(team.id))"
        }.joined(separator: "\n")

        return """
        Current SHL Season: \(resp.season.code) (Season ID: \(resp.season.id))

        Participating Teams (\(resp.teams.count) teams):
        \(teamsList)

        NOTE: Use the team CODES (e.g., 'LHF', 'RBK') when filtering matches by team in the Match Search tool.
        """
    }
}
