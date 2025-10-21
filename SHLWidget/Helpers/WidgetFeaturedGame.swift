//
//  WidgetFeaturedGame.swift
//  SHLWidget
//
//  Simple featured game selection for widgets
//

import Foundation

class WidgetFeaturedGame {
    static func getFeaturedGame(from matches: [WidgetGame]) -> WidgetGame? {
        guard !matches.isEmpty else { return nil }

        let now = Date()

        // Score each match
        let scoredMatches = matches.map { game -> (WidgetGame, Double) in
            var score: Double = 0

            let timeUntilGame = game.date.timeIntervalSince(now)

            // Future games (not played yet)
            if timeUntilGame > 0 {
                // Closer games get higher scores
                // Games within 24 hours get bonus
                if timeUntilGame < 24 * 3600 {
                    score += 1000
                }
                // Score decreases as time increases
                score += max(100 - (timeUntilGame / 3600), 0)
            } else {
                // Past games (already played)
                let timeSinceGame = -timeUntilGame
                // More recent games get higher scores
                score += max(50 - (timeSinceGame / 3600 * 2), 0)
            }

            return (game, score)
        }

        // Return the highest scored game
        return scoredMatches.max(by: { $0.1 < $1.1 })?.0
    }
}
