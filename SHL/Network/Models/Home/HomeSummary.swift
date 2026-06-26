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

    /// Which season-lifecycle variant the home should render.
    let phase: SeasonPhase
    /// Current season metadata — drives the pre-season countdown ("opening night").
    let season: SeasonMeta?
    /// The crowned team, set only in the `.concluded` phase.
    let champion: ChampionInfo?
    /// Last season's final table, set only in the `.preseason` phase (a recap).
    let previousStandings: [Standings]

    enum CodingKeys: String, CodingKey {
        case generatedAt, featured, live, upcoming, recent, standings, leaders, favorite
        case phase, season, champion, previousStandings
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
        season = try c.decodeIfPresent(SeasonMeta.self, forKey: .season)
        champion = try c.decodeIfPresent(ChampionInfo.self, forKey: .champion)
        previousStandings = try c.decodeIfPresent([Standings].self, forKey: .previousStandings) ?? []
        // Trust the server's phase; if it's absent (partial/older payload), infer it.
        if let raw = try c.decodeIfPresent(String.self, forKey: .phase),
           let parsed = SeasonPhase(rawValue: raw) {
            phase = parsed
        } else {
            phase = SeasonPhase.infer(live: live, upcoming: upcoming, recent: recent)
        }
    }

    /// Memberwise init for mocks / previews.
    init(generatedAt: Date?, phase: SeasonPhase = .regular, season: SeasonMeta? = nil,
         featured: Match?, live: [Match], upcoming: [Match],
         recent: [Match], standings: [Standings], leaders: LeagueLeaders?,
         favorite: FavoriteTeamSummary?, champion: ChampionInfo? = nil,
         previousStandings: [Standings] = []) {
        self.generatedAt = generatedAt
        self.phase = phase
        self.season = season
        self.featured = featured
        self.live = live
        self.upcoming = upcoming
        self.recent = recent
        self.standings = standings
        self.leaders = leaders
        self.favorite = favorite
        self.champion = champion
        self.previousStandings = previousStandings
    }
}

// MARK: - Season phase

/// The lifecycle state the home renders for. The server sends this; the client can
/// also infer it from the slate as a fallback.
enum SeasonPhase: String, Decodable, Equatable {
    /// Schedule published, but no games played yet — countdown to opening night.
    case preseason
    /// Games being played (regular season or playoffs) — the standard home.
    case regular
    /// The schedule is exhausted (finals done), next season's slate not out yet.
    case concluded

    /// Fallback used only when the payload omits `phase`.
    static func infer(live: [Match], upcoming: [Match], recent: [Match]) -> SeasonPhase {
        if !live.isEmpty { return .regular }
        if recent.isEmpty && !upcoming.isEmpty { return .preseason }
        if upcoming.isEmpty && !recent.isEmpty { return .concluded }
        return .regular
    }
}

/// Lightweight current-season descriptor.
struct SeasonMeta: Decodable, Equatable {
    let code: String
    let name: String
    let startDate: Date?
}

/// The crowned team for a concluded season.
struct ChampionInfo: Decodable, Equatable {
    let team: Team
    /// "Champions" (finals winner) or "Regular Season Winners" (fallback).
    let label: String
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
