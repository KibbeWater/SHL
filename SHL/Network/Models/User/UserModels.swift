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

// MARK: - User Profile

struct UserProfile: Codable {
    let id: String
    let deviceId: String
    let deviceModel: String?
    let iosVersion: String?
    let appVersion: String?
    let notificationSettings: NotificationSettings
    let favoriteTeam: FavoriteTeam?
    let createdAt: String
    let lastSeenAt: String

    var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }

    var lastSeenDate: Date? {
        return ISO8601DateFormatter().date(from: lastSeenAt)
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable, Equatable {
    /// Receive notifications 30 minutes before match starts
    var matchReminders: Bool

    /// Receive notifications when match ends with final score
    var matchResults: Bool

    /// Receive real-time goal notifications during live matches
    var liveGoals: Bool

    /// Only send notifications for user's favorite team
    var favoriteTeamOnly: Bool

    /// Receive notifications at period end (1st, 2nd, 3rd)
    var periodUpdates: Bool

    static let `default` = NotificationSettings(
        matchReminders: true,
        matchResults: true,
        liveGoals: true,
        favoriteTeamOnly: false,
        periodUpdates: false
    )
}

struct NotificationSettingsResponse: Codable {
    let success: Bool
    let settings: NotificationSettings
}

// MARK: - Favorite Team

struct FavoriteTeam: Codable {
    let id: String
    let name: String
    let code: String
    let city: String?
}

struct FavoriteTeamRequest: Codable {
    let teamId: String
}

struct FavoriteTeamResponse: Codable {
    let success: Bool
    let favoriteTeam: FavoriteTeam
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
    let deviceUUID: String
    let token: String
    let environment: String
}

struct RegisterPushTokenResponse: Codable {
    let id: String
    let deviceUUID: String
    let matchId: String
    let environment: String
}

// MARK: - User Data Export (GDPR)

struct UserDataExport: Codable {
    let userId: String
    let deviceId: String
    let notificationSettings: NotificationSettings
    let favoriteTeam: FavoriteTeam?
    let devices: [ExportedDevice]
    let favoriteTeamMatchHistory: [ExportedMatch]?
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
