//
//  PBPSupporting.swift
//  SHL
//
//  Supporting types for PBP event system
//

import Foundation

// MARK: - Player Summary

/// Simplified player information for PBP events
public struct PlayerSummary: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let firstName: String
    public let lastName: String
    public let jersey: String

    public init(id: String, firstName: String, lastName: String, jersey: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.jersey = jersey
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Team Summary

/// Team information for PBP events
public struct TeamSummary: Codable, Equatable, Sendable {
    public let id: String?
    public let code: String
    public let name: String

    public init(id: String?, code: String, name: String) {
        self.id = id
        self.code = code
        self.name = name
    }
}

// MARK: - Location Data

/// Location data for shots and goals
public struct LocationData: Codable, Equatable, Sendable {
    public let x: Int
    public let y: Int
    public let section: Int

    public init(x: Int, y: Int, section: Int) {
        self.x = x
        self.y = y
        self.section = section
    }

    /// True if shot was blocked
    public var isBlocked: Bool {
        section == -3
    }

    /// True if shot missed the net
    public var isMiss: Bool {
        section == 0
    }

    /// True if shot was on target (hit net)
    public var isOnTarget: Bool {
        section >= 1 && section <= 9
    }
}

// MARK: - Shootout Score

/// Shootout score tracking
public struct ShootoutScore: Codable, Equatable, Sendable {
    public let home: Int
    public let away: Int

    public init(home: Int, away: Int) {
        self.home = home
        self.away = away
    }
}
