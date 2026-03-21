import ComposableArchitecture
import SHLNetwork

public struct APIClient: Sendable {
    public var getLatestMatches: @Sendable () async throws -> [Match]
    public var getTeams: @Sendable () async throws -> [Team]
    public var getMatchDetail: @Sendable (_ id: String) async throws -> Match
    public var getMatchStats: @Sendable (_ id: String) async throws -> [MatchStats]
    public var getMatchEvents: @Sendable (_ id: String) async throws -> [PBPEventDTO]
    public var searchMatches: @Sendable (_ date: String?, _ team: String?, _ season: String?, _ state: String?, _ descending: Bool, _ page: Int, _ limit: Int) async throws -> PaginatedResponse<Match>
    public var getLiveMatches: @Sendable () async throws -> [Match]
    public var getTeamDetail: @Sendable (_ id: String) async throws -> Team
    public var getTeamRoster: @Sendable (_ id: String) async throws -> [Player]
    public var getTeamMatches: @Sendable (_ id: String) async throws -> [Match]
    public var getPlayerDetail: @Sendable (_ id: String) async throws -> Player
    public var getPlayerStats: @Sendable (_ id: String) async throws -> [PlayerGameLog]
    public var getCurrentSeason: @Sendable () async throws -> Season
    public var getCurrentSeasonInfo: @Sendable () async throws -> SeasonInfoResponse
    public var getAllSeasons: @Sendable () async throws -> [Season]
    public var getStandings: @Sendable (_ seasonId: String) async throws -> [Standings]
    public var getCurrentStandings: @Sendable () async throws -> [Standings]
    public var getRecentMatches: @Sendable (_ limit: Int) async throws -> RecentMatchesResponse
    public var getSeasonMatches: @Sendable (_ seasonCode: String) async throws -> [Match]
}

extension APIClient: DependencyKey {
    public static let liveValue: Self = {
        // SHLAPIClient is not Sendable, so we capture the reference once
        // and rely on its internal thread-safety (URLSession-based).
        nonisolated(unsafe) let client = SHLAPIClient.shared
        return Self(
            getLatestMatches: { try await client.getLatestMatches() },
            getTeams: { try await client.getTeams() },
            getMatchDetail: { try await client.getMatchDetail(id: $0) },
            getMatchStats: { try await client.getMatchStats(id: $0) },
            getMatchEvents: { try await client.getMatchEvents(id: $0) },
            searchMatches: { try await client.searchMatches(date: $0, team: $1, season: $2, state: $3, descending: $4, page: $5, limit: $6) },
            getLiveMatches: { try await client.getLiveMatches() },
            getTeamDetail: { try await client.getTeamDetail(id: $0) },
            getTeamRoster: { try await client.getTeamRoster(id: $0) },
            getTeamMatches: { try await client.getTeamMatches(id: $0) },
            getPlayerDetail: { try await client.getPlayerDetail(id: $0) },
            getPlayerStats: { try await client.getPlayerStats(id: $0) },
            getCurrentSeason: { try await client.getCurrentSeason() },
            getCurrentSeasonInfo: { try await client.getCurrentSeasonInfo() },
            getAllSeasons: { try await client.getAllSeasons() },
            getStandings: { try await client.getStandings(seasonId: $0) },
            getCurrentStandings: { try await client.getCurrentStandings() },
            getRecentMatches: { try await client.getRecentMatches(limit: $0) },
            getSeasonMatches: { try await client.getSeasonMatches(seasonCode: $0) }
        )
    }()

    public static let testValue = Self(
        getLatestMatches: { fatalError("unimplemented") },
        getTeams: { fatalError("unimplemented") },
        getMatchDetail: { _ in fatalError("unimplemented") },
        getMatchStats: { _ in fatalError("unimplemented") },
        getMatchEvents: { _ in fatalError("unimplemented") },
        searchMatches: { _, _, _, _, _, _, _ in fatalError("unimplemented") },
        getLiveMatches: { fatalError("unimplemented") },
        getTeamDetail: { _ in fatalError("unimplemented") },
        getTeamRoster: { _ in fatalError("unimplemented") },
        getTeamMatches: { _ in fatalError("unimplemented") },
        getPlayerDetail: { _ in fatalError("unimplemented") },
        getPlayerStats: { _ in fatalError("unimplemented") },
        getCurrentSeason: { fatalError("unimplemented") },
        getCurrentSeasonInfo: { fatalError("unimplemented") },
        getAllSeasons: { fatalError("unimplemented") },
        getStandings: { _ in fatalError("unimplemented") },
        getCurrentStandings: { fatalError("unimplemented") },
        getRecentMatches: { _ in fatalError("unimplemented") },
        getSeasonMatches: { _ in fatalError("unimplemented") }
    )
}

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
