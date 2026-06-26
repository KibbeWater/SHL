//
//  UserModels.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation
import UIKit

// MARK: - Authentication

struct AuthRequest: Codable {
    let deviceId: String
    let fallbackDeviceId: String?
    let deviceModel: String?
    let iosVersion: String?
    let appVersion: String?
}

struct AuthResponse: Codable {
    let token: String
    let userId: String
    let expiresAt: Date
}

struct TokenRefreshResponse: Codable {
    let token: String
    let userId: String
    let expiresAt: Date
}

// MARK: - Feedback

/// Body for `POST /api/v1/feedback`. Lives here (shared across targets) because the
/// API client references it; the feedback UI + category enum stay in the app target.
struct SendFeedbackRequest: Codable {
    let category: String
    let message: String
    let appVersion: String?
    let osVersion: String?
    let deviceModel: String?
}

// MARK: - User Profile

struct UserProfile: Codable {
    let id: String
    let deviceId: String
    let deviceModel: String?
    let iosVersion: String?
    let appVersion: String?
    let notificationSettings: NotificationSettings
    let interestedTeams: [InterestedTeam]
    /// Per-team level keyed by team id (added by the backend; optional for old responses).
    let interestedTeamLevels: [String: String]?
    let createdAt: String
    let lastSeenAt: String

    var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }

    var lastSeenDate: Date? {
        return ISO8601DateFormatter().date(from: lastSeenAt)
    }

    /// Interested teams with their `notifyLevel` resolved from `interestedTeamLevels`.
    var interestedTeamsWithLevels: [InterestedTeam] {
        interestedTeams.map { team in
            var resolved = team
            if let raw = interestedTeamLevels?[team.id], let level = TeamNotificationLevel(rawValue: raw) {
                resolved.notifyLevel = level
            }
            return resolved
        }
    }
}

// MARK: - Notification Settings

/// Per-team notification level. Raw values match the backend's `notify_level` column.
enum TeamNotificationLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    /// No notifications for this team
    case off
    /// Only the final score when the match ends
    case finalOnly = "final_only"
    /// All game alerts: game start, goals, and final score
    case all

    var id: String { rawValue }
}

/// App-wide notification settings synced to the backend.
/// Per-team alert levels now live on each `InterestedTeam`; this only carries the
/// global Live Activity preference.
struct NotificationSettings: Codable, Equatable {
    /// Automatically start a Live Activity before your favourite team's matches (iOS 17.2+)
    var autoStartLiveActivity: Bool

    static let `default` = NotificationSettings(autoStartLiveActivity: true)

    init(autoStartLiveActivity: Bool = true) {
        self.autoStartLiveActivity = autoStartLiveActivity
    }

    private enum CodingKeys: String, CodingKey {
        case autoStartLiveActivity
    }

    /// Tolerant decode so legacy stored values (which had extra fields) still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autoStartLiveActivity = try container.decodeIfPresent(Bool.self, forKey: .autoStartLiveActivity) ?? true
    }
}

struct NotificationSettingsResponse: Codable {
    let success: Bool
    let settings: NotificationSettings
}

// MARK: - Interested Teams

struct InterestedTeam: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let code: String
    let city: String?
    /// Per-team notification level. Not part of the team wire object — populated from
    /// the response's `levels` map (see `InterestedTeamsResponse.teamsWithLevels`).
    var notifyLevel: TeamNotificationLevel = .off

    enum CodingKeys: String, CodingKey {
        case id, name, code, city
    }
}

struct InterestedTeamsResponse: Codable {
    let teams: [InterestedTeam]
    /// Per-team level keyed by team id (added by the backend; optional for old responses).
    let levels: [String: String]?

    /// Teams with their `notifyLevel` resolved from the `levels` map.
    var teamsWithLevels: [InterestedTeam] {
        teams.map { team in
            var resolved = team
            if let raw = levels?[team.id], let level = TeamNotificationLevel(rawValue: raw) {
                resolved.notifyLevel = level
            }
            return resolved
        }
    }
}

/// One team + its notification level, for the level-aware "set interested teams" request.
struct InterestedTeamLevelPayload: Codable {
    let teamId: String
    let level: String
}

struct SetInterestedTeamsRequest: Codable {
    let teams: [InterestedTeamLevelPayload]
}

/// Body for PATCH /user/interested-teams/:teamId
struct UpdateTeamLevelRequest: Codable {
    let level: String
}

// MARK: - Device Management

struct Device: Codable, Identifiable {
    let id: String
    let deviceId: String
    let deviceName: String
    let deviceModel: String?
    let iosVersion: String?
    let appVersion: String?
    let lastSeenAt: String
    let notificationsEnabled: Bool
    let pushTokenCount: Int
    let createdAt: String

    var lastSeenDate: Date? {
        return ISO8601DateFormatter().date(from: lastSeenAt)
    }

    var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }
}

struct DevicesResponse: Codable {
    let devices: [Device]
    let total: Int
}

struct UpdateDeviceRequest: Codable {
    let deviceName: String?
    let notificationsEnabled: Bool?
}

// MARK: - Push Tokens

struct PushToken: Codable, Identifiable {
    let id: String
    let matchId: String
    let environment: String
    let deviceName: String
    let expiresAt: String
    let createdAt: String

    var expirationDate: Date? {
        return ISO8601DateFormatter().date(from: expiresAt)
    }

    var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }
}

struct PushTokensResponse: Codable {
    let tokens: [PushToken]
    let total: Int
}

struct RegisterPushTokenRequest: Codable {
    let token: String
    let deviceId: String
    let type: String
    let teamCode: String?
    let matchId: String?
    let environment: String?

    init(token: String, deviceId: String, type: String = "regular", teamCode: String? = nil, matchId: String? = nil, environment: String? = "production") {
        self.token = token
        self.deviceId = deviceId
        self.type = type
        self.teamCode = teamCode
        self.matchId = matchId
        self.environment = environment
    }
}

struct RegisterPushTokenResponse: Codable {
    let success: Bool?
    let message: String?
}

// MARK: - User Data Export (GDPR)

struct UserDataExport: Codable {
    let userId: String
    let deviceId: String
    let notificationSettings: NotificationSettings
    let interestedTeams: [InterestedTeam]?
    let devices: [ExportedDevice]
    let interestedTeamsMatchHistory: [ExportedMatch]?
}

struct ExportedDevice: Codable {
    let deviceId: String
    let deviceName: String
    let pushTokenCount: Int
    let lastSeenAt: String
}

struct ExportedMatch: Codable {
    let matchId: String
    let gameDate: String
    let homeScore: Int?
    let awayScore: Int?
}

// MARK: - API Error Response

struct APIErrorResponse: Codable, Error {
    let error: Bool
    let reason: String
    let code: String?
    let timestamp: String

    var errorDate: Date? {
        return ISO8601DateFormatter().date(from: timestamp)
    }
}

// MARK: - Helper Extensions

extension UIDevice {
    /// Get detailed device model identifier (e.g., "iPhone15,3")
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// Get human-readable device name (e.g., "iPhone 15 Pro")
    static var deviceName: String {
        let identifier = modelIdentifier

        // Map device identifiers to names
        switch identifier {
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPad13,1", "iPad13,2": return "iPad Air (5th gen)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th gen)"
        default:
            // Fallback to generic name
            if identifier.hasPrefix("iPhone") {
                return "iPhone"
            } else if identifier.hasPrefix("iPad") {
                return "iPad"
            }
            return "iOS Device"
        }
    }
}

extension Bundle {
    /// Get app version string
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Get build number
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Get full version string (e.g., "1.0.5 (42)")
    var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}
