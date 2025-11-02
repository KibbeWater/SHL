//
//  MatchSearch.swift
//  SHL
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
struct MatchSearch: Tool {
    let name: String = "Match Search"
    let description: String = """
    Search for SHL hockey matches with flexible filtering. Use this tool to find past results or upcoming games. \
    Apply filters strategically based on user intent:
    - Use 'date' for matches on a specific day
    - Use 'team' to filter by a specific team (home or away)
    - Use 'season' to search specific years (searches all seasons if omitted)
    - Use 'state' to filter by match status based on user request

    IMPORTANT: ALWAYS call 'Get Season Information' tool first to discover valid team codes before filtering by team.
    """

    @Generable
    struct Arguments {
        @Guide(description: "Exact date to search for matches (format: YYYY-MM-DD, e.g., '2025-01-15'). Only matches on this specific date will be returned. Omit to search across all dates.")
        let date: String?
        @Guide(description: "Single team code to filter matches where this team plays (home or away). Examples: 'LHF' for Luleå, 'RBK' for Rögle. REQUIRED: Must first call 'Get Season Information' to discover valid team codes. Omit to search all teams.")
        let team: String?
        @Guide(description: "Season year to search (e.g., '2025', '2024'). Must first call 'Get Season Information' to discover valid season codes. Omit to search only the current active season.")
        let season: String?
        @Guide(description: "Match status filter based on user intent: 'scheduled' for upcoming/future games, 'played' for past/completed games, 'ongoing' for live/current matches, 'all' for any status. Choose wisely: 'next games' → 'scheduled', 'previous games' → 'played', 'today's games' → 'all'.", .anyOf(["all", "scheduled", "ongoing", "played"]))
        let state: String

        @Guide(description: "Page number for pagination (default: 1). Increment to fetch additional results when total matches exceed the limit.")
        let page: Int?
        @Guide(description: "Number of matches to return per page (1-100, default: 20). Use smaller values for 'next few games' (e.g., 5-10), larger values for comprehensive searches (e.g., 50+).", .range(1 ... 100))
        let limit: Int?
    }

    func call(arguments: Arguments) async throws -> String {
        let response = try await SHLAPIClient.shared.searchMatches(
            date: arguments.date,
            team: arguments.team,
            season: arguments.season,
            state: arguments.state == "all" ? nil : arguments.state,
            descending: false,
            page: arguments.page ?? 1,
            limit: arguments.limit ?? 20
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let matchesDesc = response.data.map { match in
            let dateStr = dateFormatter.string(from: match.date)
            let score = "\(match.homeScore)-\(match.awayScore)"
            let overtime = match.overtime == true ? " (OT)" : ""
            let shootout = match.shootout == true ? " (SO)" : ""
            let statusLabel: String
            switch match.state {
            case .scheduled: statusLabel = "SCHEDULED"
            case .ongoing: statusLabel = "LIVE"
            case .played: statusLabel = "FINAL"
            case .paused: statusLabel = "PAUSED"
            }
            return "[\(statusLabel)] \(dateStr) | \(match.homeTeam.name) vs \(match.awayTeam.name) - \(score)\(overtime)\(shootout)"
        }.joined(separator: "\n")

        let totalPages = (response.total + response.limit - 1) / response.limit
        let paginationInfo = totalPages > 1 ? " (Page \(response.page) of \(totalPages))" : ""

        if response.data.isEmpty {
            return "No matches found matching your search criteria. Try adjusting your filters or search parameters."
        }

        return """
        Found \(response.total) total match\(response.total == 1 ? "" : "es")\(paginationInfo):

        \(matchesDesc)

        \(totalPages > response.page ? "\nNote: More results available. Use page=\(response.page + 1) to see the next page." : "")
        """
    }
}
