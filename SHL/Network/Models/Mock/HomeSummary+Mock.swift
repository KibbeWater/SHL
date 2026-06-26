//
//  HomeSummary+Mock.swift
//  SHL
//
//  Realistic preview data for the redesigned home screen. The v2 endpoint isn't
//  live yet, so previews and the loading-fallback render from this. Frölunda is
//  the stand-in favorite team.
//

import Foundation

extension HomeSummary {
    /// A fully-populated summary: a live featured game, a couple more live games,
    /// upcoming + recent slates, a full table, leaders, and a favorite block.
    static var mock: HomeSummary {
        HomeSummary(
            generatedAt: Date(),
            featured: MockHome.featured,
            live: MockHome.live,
            upcoming: MockHome.upcoming,
            recent: MockHome.recent,
            standings: MockHome.standings,
            leaders: MockHome.leaders,
            favorite: MockHome.favorite
        )
    }

    /// A summary for a user with no favorite team picked.
    static var mockNoFavorite: HomeSummary {
        HomeSummary(
            generatedAt: Date(), featured: MockHome.featured, live: MockHome.live,
            upcoming: MockHome.upcoming, recent: MockHome.recent,
            standings: MockHome.standings, leaders: MockHome.leaders, favorite: nil
        )
    }

    /// A quiet day: nothing live, no favorite, just upcoming + standings.
    static var mockQuiet: HomeSummary {
        HomeSummary(
            generatedAt: Date(), featured: MockHome.upcoming.first, live: [],
            upcoming: MockHome.upcoming, recent: MockHome.recent,
            standings: MockHome.standings, leaders: MockHome.leaders, favorite: nil
        )
    }
}

private enum MockHome {
    static func team(_ code: String, _ name: String, _ city: String) -> Team {
        Team(id: "team-\(code)", name: name, code: code, city: city, founded: 1938,
             venue: nil, golds: code == "FHC" ? 4 : 1, goldYears: nil, finals: nil,
             finalYears: nil, iconURL: nil, isActive: true)
    }

    static func basic(_ code: String, _ name: String) -> TeamBasic {
        TeamBasic(id: "team-\(code)", name: name, code: code)
    }

    static func match(_ id: String, _ home: (String, String), _ away: (String, String),
                      hs: Int, aws: Int, state: MatchState, inHours: Double,
                      venue: String? = nil, ot: Bool = false) -> Match {
        Match(id: id,
              date: Date().addingTimeInterval(inHours * 3600),
              venue: venue,
              homeTeam: basic(home.0, home.1),
              awayTeam: basic(away.0, away.1),
              homeScore: hs, awayScore: aws, state: state,
              overtime: ot, shootout: false, externalUUID: "ext-\(id)")
    }

    // MARK: Featured + live

    static let featured = match("m-feat", ("FHC", "Frölunda HC"), ("LHF", "Luleå HF"),
                                hs: 2, aws: 1, state: .ongoing, inHours: -0.6,
                                venue: "Frölundaborg")

    static let live: [Match] = [
        featured,
        match("m-live2", ("SAIK", "Skellefteå AIK"), ("RBK", "Rögle BK"),
              hs: 0, aws: 0, state: .ongoing, inHours: -0.3, venue: "Be-Ge Hockey Center"),
        match("m-live3", ("FBK", "Färjestad BK"), ("VLH", "Växjö Lakers"),
              hs: 3, aws: 2, state: .ongoing, inHours: -1.1, venue: "Löfbergs Arena")
    ]

    // MARK: Upcoming

    static let upcoming: [Match] = [
        match("m-up1", ("FHC", "Frölunda HC"), ("FBK", "Färjestad BK"), hs: 0, aws: 0, state: .scheduled, inHours: 26, venue: "Frölundaborg"),
        match("m-up2", ("LHF", "Luleå HF"), ("MODO", "MoDo Hockey"), hs: 0, aws: 0, state: .scheduled, inHours: 27),
        match("m-up3", ("RBK", "Rögle BK"), ("LIF", "Leksands IF"), hs: 0, aws: 0, state: .scheduled, inHours: 50),
        match("m-up4", ("VLH", "Växjö Lakers"), ("SAIK", "Skellefteå AIK"), hs: 0, aws: 0, state: .scheduled, inHours: 51),
        match("m-up5", ("MODO", "MoDo Hockey"), ("FHC", "Frölunda HC"), hs: 0, aws: 0, state: .scheduled, inHours: 74)
    ]

    // MARK: Recent

    static let recent: [Match] = [
        match("m-rec1", ("FHC", "Frölunda HC"), ("MODO", "MoDo Hockey"), hs: 4, aws: 2, state: .played, inHours: -22),
        match("m-rec2", ("LHF", "Luleå HF"), ("VLH", "Växjö Lakers"), hs: 1, aws: 2, state: .played, inHours: -23, ot: true),
        match("m-rec3", ("SAIK", "Skellefteå AIK"), ("FBK", "Färjestad BK"), hs: 3, aws: 0, state: .played, inHours: -46),
        match("m-rec4", ("LIF", "Leksands IF"), ("RBK", "Rögle BK"), hs: 2, aws: 5, state: .played, inHours: -47)
    ]

    // MARK: Standings

    static let standings: [Standings] = {
        let rows: [(String, String, String, Int, Int, Int, Int, Int, Int, Int)] = [
            // code, name, city, gp, w, otw, otl, l, pts, gd
            ("LHF", "Luleå HF", "Luleå", 38, 24, 4, 3, 7, 83, 41),
            ("SAIK", "Skellefteå AIK", "Skellefteå", 38, 22, 5, 4, 7, 80, 33),
            ("FHC", "Frölunda HC", "Göteborg", 38, 21, 4, 5, 8, 76, 28),
            ("FBK", "Färjestad BK", "Karlstad", 38, 19, 5, 4, 10, 71, 19),
            ("RBK", "Rögle BK", "Ängelholm", 38, 18, 3, 6, 11, 66, 8),
            ("VLH", "Växjö Lakers", "Växjö", 38, 16, 5, 5, 12, 63, 4),
            ("LIF", "Leksands IF", "Leksand", 38, 14, 3, 6, 15, 54, -6),
            ("MODO", "MoDo Hockey", "Örnsköldsvik", 38, 11, 4, 5, 18, 46, -22)
        ]
        return rows.enumerated().map { idx, r in
            Standings(id: "st-\(r.0)", seasonID: "2024-25",
                      team: team(r.0, r.1, r.2),
                      rank: idx + 1, gamesPlayed: r.3, points: r.8, goalDifference: r.9,
                      wins: r.4, overtimeWins: r.5, losses: r.7, overtimeLosses: r.6,
                      goalsFor: nil, goalsAgainst: nil)
        }
    }()

    // MARK: Leaders

    static let leaders = LeagueLeaders(boards: [
        LeaderBoard(id: "points", title: "Points", entries: [
            LeaderEntry(playerId: "p1", playerName: "Linus Johansson", teamCode: "FHC", teamId: "team-FHC", jerseyNumber: 23, portraitURL: nil, value: 52, display: "52"),
            LeaderEntry(playerId: "p2", playerName: "Jonathan Pudas", teamCode: "SAIK", teamId: "team-SAIK", jerseyNumber: 5, portraitURL: nil, value: 48, display: "48"),
            LeaderEntry(playerId: "p3", playerName: "Pontus Andreasson", teamCode: "LHF", teamId: "team-LHF", jerseyNumber: 19, portraitURL: nil, value: 47, display: "47")
        ]),
        LeaderBoard(id: "goals", title: "Goals", entries: [
            LeaderEntry(playerId: "g1", playerName: "Rasmus Dahlin", teamCode: "FBK", teamId: "team-FBK", jerseyNumber: 8, portraitURL: nil, value: 24, display: "24"),
            LeaderEntry(playerId: "g2", playerName: "Linus Johansson", teamCode: "FHC", teamId: "team-FHC", jerseyNumber: 23, portraitURL: nil, value: 22, display: "22"),
            LeaderEntry(playerId: "g3", playerName: "Marcus Sörensen", teamCode: "RBK", teamId: "team-RBK", jerseyNumber: 20, portraitURL: nil, value: 21, display: "21")
        ]),
        LeaderBoard(id: "save_pct", title: "Save %", entries: [
            LeaderEntry(playerId: "s1", playerName: "Lars Johansson", teamCode: "FHC", teamId: "team-FHC", jerseyNumber: 30, portraitURL: nil, value: 0.928, display: ".928"),
            LeaderEntry(playerId: "s2", playerName: "Joel Lassinantti", teamCode: "LHF", teamId: "team-LHF", jerseyNumber: 32, portraitURL: nil, value: 0.921, display: ".921"),
            LeaderEntry(playerId: "s3", playerName: "Gustaf Lindvall", teamCode: "VLH", teamId: "team-VLH", jerseyNumber: 35, portraitURL: nil, value: 0.919, display: ".919")
        ])
    ])

    // MARK: Favorite

    static let favorite = FavoriteTeamSummary(
        team: basic("FHC", "Frölunda HC"),
        teamId: "team-FHC",
        rank: 3, points: 76, gamesPlayed: 38,
        form: [.win, .loss, .otWin, .win, .win],
        nextMatch: upcoming.first,
        lastMatch: recent.first
    )
}
