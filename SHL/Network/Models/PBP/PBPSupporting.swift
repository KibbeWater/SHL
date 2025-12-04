//
//  PBPSupporting.swift
//  SHL
//
//  Supporting types for PBP event system
//

import Foundation

// MARK: - Player Summary

/// Simplified player information for PBP events
struct PlayerSummary: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let firstName: String
    let lastName: String
    let jersey: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Team Summary

/// Team information for PBP events
struct TeamSummary: Codable, Equatable, Sendable {
    let id: String?
    let code: String
    let name: String
}

// MARK: - Location Data

/// Location data for shots and goals
struct LocationData: Codable, Equatable, Sendable {
    let x: Int
    let y: Int
    let section: Int

    /// True if shot was blocked
    var isBlocked: Bool {
        section == -3
    }

    /// True if shot missed the net
    var isMiss: Bool {
        section == 0
    }

    /// True if shot was on target (hit net)
    var isOnTarget: Bool {
        section >= 1 && section <= 9
    }
}

// MARK: - Shootout Score

/// Shootout score tracking
struct ShootoutScore: Codable, Equatable, Sendable {
    let home: Int
    let away: Int
}
