//
//  ScheduleSummary.swift
//  SHL
//
//  The comprehensive v2 DTO for the Schedule screen —
//  `GET /api/v2/schedule?from=&to=&team=`. One call delivers everything the
//  schedule needs to function, so the client doesn't fan out into /teams,
//  per-game /live, and a "next game" lookup:
//
//  • matches       — the games within the requested range (a visible week)
//  • teams         — the full team list, for the filter menu
//  • live          — live data for any in-progress games, layered over the slate
//  • nextScheduled — the soonest upcoming game, to skip an empty "today"
//  • gameDays      — every date with a game ("yyyy-MM-dd"), to dot the week strip
//
//  All fields are optional on the wire (decoded with defaults), so a partial
//  payload still works and the client falls back to the v1 calls for anything
//  the backend hasn't filled in yet.
//

import Foundation

struct ScheduleSummary: Decodable {
    let matches: [Match]
    let teams: [Team]
    let live: [LiveMatch]
    let nextScheduled: Match?
    let gameDays: [String]

    enum CodingKeys: String, CodingKey {
        case matches, teams, live, nextScheduled, gameDays
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        matches = try c.decodeIfPresent([Match].self, forKey: .matches) ?? []
        teams = try c.decodeIfPresent([Team].self, forKey: .teams) ?? []
        live = try c.decodeIfPresent([LiveMatch].self, forKey: .live) ?? []
        nextScheduled = try c.decodeIfPresent(Match.self, forKey: .nextScheduled)
        gameDays = try c.decodeIfPresent([String].self, forKey: .gameDays) ?? []
    }

    init(matches: [Match], teams: [Team] = [], live: [LiveMatch] = [],
         nextScheduled: Match? = nil, gameDays: [String] = []) {
        self.matches = matches
        self.teams = teams
        self.live = live
        self.nextScheduled = nextScheduled
        self.gameDays = gameDays
    }
}
