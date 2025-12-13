//
//  WidgetUserPreferences.swift
//  SHLWidget
//
//  Reads user team preferences from App Group (populated by main app)
//

import Foundation

/// Reads user preferences from the App Group container (populated by main app)
class WidgetUserPreferences {
    static let shared = WidgetUserPreferences()

    private let appGroupID = "group.kibbewater.shl"
    private let interestedCodesKey = "widget_interested_team_codes"
    private let favoriteCodeKey = "widget_favorite_team_code"

    private init() {}

    // MARK: - Public API

    /// Get the user's interested team codes (e.g., ["LHF", "FHC"])
    var interestedTeamCodes: [String] {
        let defaults = UserDefaults(suiteName: appGroupID)
        return defaults?.stringArray(forKey: interestedCodesKey) ?? []
    }

    /// Get the user's favorite team code (e.g., "LHF")
    var favoriteTeamCode: String? {
        let defaults = UserDefaults(suiteName: appGroupID)
        return defaults?.string(forKey: favoriteCodeKey)
    }

    /// Check if a team code is in the user's interested teams
    func isInterestedTeam(_ code: String) -> Bool {
        interestedTeamCodes.contains(code.uppercased())
    }

    /// Check if a team code is the user's favorite
    func isFavoriteTeam(_ code: String) -> Bool {
        favoriteTeamCode?.uppercased() == code.uppercased()
    }

    /// Check if a game involves any interested teams
    func gameInvolvesInterestedTeam(_ game: WidgetGame) -> Bool {
        isInterestedTeam(game.homeTeam.code) || isInterestedTeam(game.awayTeam.code)
    }

    /// Check if a game involves the favorite team
    func gameInvolvesFavoriteTeam(_ game: WidgetGame) -> Bool {
        isFavoriteTeam(game.homeTeam.code) || isFavoriteTeam(game.awayTeam.code)
    }
}
