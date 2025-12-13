//
//  TeamColorCache.swift
//  SHLWidget
//
//  Reads team colors from shared App Group cache populated by main app
//

import SwiftUI

struct TeamColorCache {
    // Fallback colors if shared cache is not populated
    private static let fallbackColors: [String: Color] = [
        "LHF": Color(red: 0.86, green: 0.64, blue: 0.0),
        "FHC": Color(red: 0.0, green: 0.47, blue: 0.31),
        "SKE": Color(red: 0.93, green: 0.79, blue: 0.0),
        "FBK": Color(red: 0.0, green: 0.53, blue: 0.27),
        "RBK": Color(red: 0.85, green: 0.11, blue: 0.14),
        "VLH": Color(red: 0.0, green: 0.18, blue: 0.42),
        "IKO": Color(red: 0.0, green: 0.36, blue: 0.62),
        "HV71": Color(red: 0.0, green: 0.25, blue: 0.53),
        "MIF": Color(red: 0.93, green: 0.11, blue: 0.14),
        "LIF": Color(red: 0.0, green: 0.53, blue: 0.22),
        "BIF": Color(red: 0.0, green: 0.0, blue: 0.55),
        "TIK": Color(red: 0.0, green: 0.47, blue: 0.75),
        "LHC": Color(red: 0.0, green: 0.40, blue: 0.26),
        "MODO": Color(red: 0.87, green: 0.09, blue: 0.05),
        "OHK": Color(red: 0.3, green: 0.3, blue: 0.3),
        "ÖRE": Color(red: 0.3, green: 0.3, blue: 0.3),
        "DIF": Color(red: 0.0, green: 0.30, blue: 0.60),
        "SAIK": Color(red: 0.93, green: 0.79, blue: 0.0),
        "TBD": Color.gray
    ]

    /// Get the color for a team by its code
    /// First tries shared cache from main app, falls back to hardcoded colors
    static func color(for teamCode: String) -> Color {
        let code = teamCode.uppercased()

        // Try shared cache first (populated by main app)
        if let sharedColor = WidgetSharedColorCache.shared.getColor(forTeamCode: code) {
            return sharedColor
        }

        // Fallback to hardcoded colors
        return fallbackColors[code] ?? .gray
    }

    /// Get colors for both teams as a gradient
    /// - Parameters:
    ///   - homeTeamCode: Home team code
    ///   - awayTeamCode: Away team code
    /// - Returns: A linear gradient from home to away team colors
    static func gradient(home homeTeamCode: String, away awayTeamCode: String) -> LinearGradient {
        LinearGradient(
            colors: [
                color(for: homeTeamCode).opacity(0.35),
                .clear,
                .clear,
                color(for: awayTeamCode).opacity(0.35)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Get a diagonal gradient for small widgets
    /// - Parameters:
    ///   - homeTeamCode: Home team code
    ///   - awayTeamCode: Away team code
    /// - Returns: A diagonal linear gradient
    static func diagonalGradient(home homeTeamCode: String, away awayTeamCode: String) -> LinearGradient {
        LinearGradient(
            colors: [
                color(for: homeTeamCode).opacity(0.35),
                .clear,
                .clear,
                color(for: awayTeamCode).opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
