//
//  HomeSummary.swift
//  SHL
//
//  The v2 "summary" DTO. Where the v1 home assembled itself from ~30 client
//  requests (featured algo, recent, live, standings, per-team detail…), v2
//  returns one compound response — `GET /api/v2/home` — that bundles everything
//  the home screen needs. It deliberately *reuses* the existing wire models
//  (`Match`, `Standings`, `TeamBasic`) and adds only the small, summary-shaped
//  pieces the client can't cheaply derive (league leaders, the personalized
//  favorite-team block).
//

import Foundation

/// Everything the redesigned home screen renders, in one response.
struct HomeSummary: Decodable, Equatable {
    /// When the backend assembled this payload (for "updated just now" UI / caching).
    let generatedAt: Date?

    /// The single most relevant game right now (live > favorite/interested > soon).
    let featured: Match?
    /// Games currently in progress, for the "Live Now" rail.
    let live: [Match]
    /// Next games, soonest first.
    let upcoming: [Match]
    /// Most recent finished games, newest first.
    let recent: [Match]
    /// Current league table.
    let standings: [Standings]
    /// League stat leaders, grouped into boards (points, goals, save %…). Optional
    /// so older/partial payloads still decode.
    let leaders: LeagueLeaders?
    /// The personalized block for the user's favorite team. `nil` when the user
    /// hasn't picked one.
    let favorite: FavoriteTeamSummary?

    enum CodingKeys: String, CodingKey {
        case generatedAt, featured, live, upcoming, recent, standings, leaders, favorite
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try c.decodeIfPresent(Date.self, forKey: .generatedAt)
        featured = try c.decodeIfPresent(Match.self, forKey: .featured)
        // Arrays default to empty so a missing key never fails the whole payload.
        live = try c.decodeIfPresent([Match].self, forKey: .live) ?? []
        upcoming = try c.decodeIfPresent([Match].self, forKey: .upcoming) ?? []
        recent = try c.decodeIfPresent([Match].self, forKey: .recent) ?? []
        standings = try c.decodeIfPresent([Standings].self, forKey: .standings) ?? []
        leaders = try c.decodeIfPresent(LeagueLeaders.self, forKey: .leaders)
        favorite = try c.decodeIfPresent(FavoriteTeamSummary.self, forKey: .favorite)
    }

    /// Memberwise init for mocks / previews.
    init(generatedAt: Date?, featured: Match?, live: [Match], upcoming: [Match],
         recent: [Match], standings: [Standings], leaders: LeagueLeaders?,
         favorite: FavoriteTeamSummary?) {
        self.generatedAt = generatedAt
        self.featured = featured
        self.live = live
        self.upcoming = upcoming
        self.recent = recent
        self.standings = standings
        self.leaders = leaders
        self.favorite = favorite
    }
}

// MARK: - League leaders

/// A set of stat leaderboards. Modeled as a list of boards rather than fixed
/// fields so the backend can add categories (PIM, +/−, …) without a client change.
struct LeagueLeaders: Decodable, Equatable {
    let boards: [LeaderBoard]
}

/// One leaderboard — e.g. "Points", "Goals", "Save %".
struct LeaderBoard: Decodable, Equatable, Identifiable {
    /// Stable key, e.g. "points". Also the SF Symbol hint is chosen client-side.
    let id: String
    let title: String
    let entries: [LeaderEntry]
}

/// One ranked player on a leaderboard. Lightweight on purpose — it carries only
/// what a compact leader row shows, with `display` pre-formatted by the backend
/// (so "62" for points, ".928" for save %).
struct LeaderEntry: Decodable, Equatable, Identifiable {
    let playerId: String
    let playerName: String
    let teamCode: String
    let teamId: String?
    let jerseyNumber: Int?
    let portraitURL: String?
    /// Numeric value (for sorting / accessibility).
    let value: Double
    /// Pre-formatted value for display.
    let display: String

    var id: String { playerId }
}

// MARK: - Favorite-team summary

/// A single recent result, oldest → newest, for the form pips.
enum FormOutcome: String, Decodable, Equatable {
    case win = "W"
    case otWin = "OTW"
    case otLoss = "OTL"
    case loss = "L"
}

/// The personalized block: where the favorite team sits, how they've been
/// playing, and their next + last game.
struct FavoriteTeamSummary: Decodable, Equatable {
    let team: TeamBasic
    let teamId: String?
    let rank: Int?
    let points: Int?
    let gamesPlayed: Int?
    /// Last five results, oldest → newest.
    let form: [FormOutcome]
    let nextMatch: Match?
    let lastMatch: Match?
}
