//
//  WidgetFeaturedGame.swift
//  SHLWidget
//
//  Featured game selection with user preference support
//

import Foundation

class WidgetFeaturedGame {
    static func getFeaturedGame(from matches: [WidgetGame]) -> WidgetGame? {
        guard !matches.isEmpty else { return nil }

        let now = Date()
        let preferences = WidgetUserPreferences.shared

        // Score each match
        let scoredMatches = matches.map { game -> (WidgetGame, Double) in
            var score: Double = 0

            // Favorite team gets highest priority bonus
            if preferences.gameInvolvesFavoriteTeam(game) {
                score += 750
            }
            // Interested teams get bonus (lower than favorite)
            else if preferences.gameInvolvesInterestedTeam(game) {
                score += 500
            }

            let timeUntilGame = game.date.timeIntervalSince(now)

            // Future games (not played yet)
            if timeUntilGame > 0 {
                // Games within 24 hours get bonus
                if timeUntilGame < 24 * 3600 {
                    score += 1000
                }
                // Score decreases logarithmically as time increases
                score += max(100 - log10(max(timeUntilGame / 3600, 1)) * 20, 0)
            } else {
                // Past games (already played)
                let timeSinceGame = -timeUntilGame
                // More recent games get higher scores
                score += max(50 - log10(max(timeSinceGame / 3600, 1)) * 10, 0)
            }

            return (game, score)
        }

        // Return the highest scored game
        return scoredMatches.max(by: { $0.1 < $1.1 })?.0
    }
}
