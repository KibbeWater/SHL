//
//  UserModels.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Authentication

public struct AuthRequest: Codable {
    public let deviceId: String
    public let fallbackDeviceId: String?
    public let deviceModel: String?
    public let iosVersion: String?
    public let appVersion: String?

    public init(deviceId: String, fallbackDeviceId: String?, deviceModel: String?, iosVersion: String?, appVersion: String?) {
        self.deviceId = deviceId
        self.fallbackDeviceId = fallbackDeviceId
        self.deviceModel = deviceModel
        self.iosVersion = iosVersion
        self.appVersion = appVersion
    }
}

public struct AuthResponse: Codable {
    public let token: String
    public let userId: String
    public let expiresAt: Date

    public init(token: String, userId: String, expiresAt: Date) {
        self.token = token
        self.userId = userId
        self.expiresAt = expiresAt
    }
}

public struct TokenRefreshResponse: Codable {
    public let token: String
    public let userId: String
    public let expiresAt: Date

    public init(token: String, userId: String, expiresAt: Date) {
        self.token = token
        self.userId = userId
        self.expiresAt = expiresAt
    }
}

// MARK: - User Profile

public struct UserProfile: Codable {
    public let id: String
    public let deviceId: String
    public let deviceModel: String?
    public let iosVersion: String?
    public let appVersion: String?
    public let notificationSettings: NotificationSettings
    public let interestedTeams: [InterestedTeam]
    public let createdAt: String
    public let lastSeenAt: String

    public init(id: String, deviceId: String, deviceModel: String?, iosVersion: String?, appVersion: String?, notificationSettings: NotificationSettings, interestedTeams: [InterestedTeam], createdAt: String, lastSeenAt: String) {
        self.id = id
        self.deviceId = deviceId
        self.deviceModel = deviceModel
        self.iosVersion = iosVersion
        self.appVersion = appVersion
        self.notificationSettings = notificationSettings
        self.interestedTeams = interestedTeams
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
    }

    public var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }

    public var lastSeenDate: Date? {
        return ISO8601DateFormatter().date(from: lastSeenAt)
    }
}

// MARK: - Notification Settings

public struct NotificationSettings: Codable, Equatable {
    /// Receive notifications 30 minutes before match starts
    public var matchReminders: Bool

    /// Receive notifications when match ends with final score
    public var matchResults: Bool

    /// Receive real-time goal notifications during live matches
    public var liveGoals: Bool

    /// Receive notifications at period end (1st, 2nd, 3rd)
    public var periodUpdates: Bool

    /// Automatically start Live Activity before interested team's matches
    public var autoStartLiveActivity: Bool

    public static let `default` = NotificationSettings(
        matchReminders: true,
        matchResults: true,
        liveGoals: true,
        periodUpdates: false,
        autoStartLiveActivity: true
    )

    public init(matchReminders: Bool, matchResults: Bool, liveGoals: Bool, periodUpdates: Bool, autoStartLiveActivity: Bool) {
        self.matchReminders = matchReminders
        self.matchResults = matchResults
        self.liveGoals = liveGoals
        self.periodUpdates = periodUpdates
        self.autoStartLiveActivity = autoStartLiveActivity
    }
}

public struct NotificationSettingsResponse: Codable {
    public let success: Bool
    public let settings: NotificationSettings

    public init(success: Bool, settings: NotificationSettings) {
        self.success = success
        self.settings = settings
    }
}

// MARK: - Interested Teams

public struct InterestedTeam: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let code: String
    public let city: String?

    public init(id: String, name: String, code: String, city: String?) {
        self.id = id
        self.name = name
        self.code = code
        self.city = city
    }
}

public struct InterestedTeamsResponse: Codable {
    public let teams: [InterestedTeam]

    public init(teams: [InterestedTeam]) {
        self.teams = teams
    }
}

public struct SetInterestedTeamsRequest: Codable {
    public let teamIds: [String]

    public init(teamIds: [String]) {
        self.teamIds = teamIds
    }
}

// MARK: - Device Management

public struct Device: Codable, Identifiable {
    public let id: String
    public let deviceId: String
    public let deviceName: String
    public let deviceModel: String?
    public let iosVersion: String?
    public let appVersion: String?
    public let lastSeenAt: String
    public let notificationsEnabled: Bool
    public let pushTokenCount: Int
    public let createdAt: String

    public init(id: String, deviceId: String, deviceName: String, deviceModel: String?, iosVersion: String?, appVersion: String?, lastSeenAt: String, notificationsEnabled: Bool, pushTokenCount: Int, createdAt: String) {
        self.id = id
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.iosVersion = iosVersion
        self.appVersion = appVersion
        self.lastSeenAt = lastSeenAt
        self.notificationsEnabled = notificationsEnabled
        self.pushTokenCount = pushTokenCount
        self.createdAt = createdAt
    }

    public var lastSeenDate: Date? {
        return ISO8601DateFormatter().date(from: lastSeenAt)
    }

    public var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }
}

public struct DevicesResponse: Codable {
    public let devices: [Device]
    public let total: Int

    public init(devices: [Device], total: Int) {
        self.devices = devices
        self.total = total
    }
}

public struct UpdateDeviceRequest: Codable {
    public let deviceName: String?
    public let notificationsEnabled: Bool?

    public init(deviceName: String?, notificationsEnabled: Bool?) {
        self.deviceName = deviceName
        self.notificationsEnabled = notificationsEnabled
    }
}

// MARK: - Push Tokens

public struct PushToken: Codable, Identifiable {
    public let id: String
    public let matchId: String
    public let environment: String
    public let deviceName: String
    public let expiresAt: String
    public let createdAt: String

    public init(id: String, matchId: String, environment: String, deviceName: String, expiresAt: String, createdAt: String) {
        self.id = id
        self.matchId = matchId
        self.environment = environment
        self.deviceName = deviceName
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    public var expirationDate: Date? {
        return ISO8601DateFormatter().date(from: expiresAt)
    }

    public var creationDate: Date? {
        return ISO8601DateFormatter().date(from: createdAt)
    }
}

public struct PushTokensResponse: Codable {
    public let tokens: [PushToken]
    public let total: Int

    public init(tokens: [PushToken], total: Int) {
        self.tokens = tokens
        self.total = total
    }
}

public struct RegisterPushTokenRequest: Codable {
    public let token: String
    public let deviceId: String
    public let type: String
    public let teamCode: String?
    public let matchId: String?
    public let environment: String?

    public init(token: String, deviceId: String, type: String = "regular", teamCode: String? = nil, matchId: String? = nil, environment: String? = "production") {
        self.token = token
        self.deviceId = deviceId
        self.type = type
        self.teamCode = teamCode
        self.matchId = matchId
        self.environment = environment
    }
}

public struct RegisterPushTokenResponse: Codable {
    public let success: Bool?
    public let message: String?

    public init(success: Bool?, message: String?) {
        self.success = success
        self.message = message
    }
}

// MARK: - User Data Export (GDPR)

public struct UserDataExport: Codable {
    public let userId: String
    public let deviceId: String
    public let notificationSettings: NotificationSettings
    public let interestedTeams: [InterestedTeam]?
    public let devices: [ExportedDevice]
    public let interestedTeamsMatchHistory: [ExportedMatch]?

    public init(userId: String, deviceId: String, notificationSettings: NotificationSettings, interestedTeams: [InterestedTeam]?, devices: [ExportedDevice], interestedTeamsMatchHistory: [ExportedMatch]?) {
        self.userId = userId
        self.deviceId = deviceId
        self.notificationSettings = notificationSettings
        self.interestedTeams = interestedTeams
        self.devices = devices
        self.interestedTeamsMatchHistory = interestedTeamsMatchHistory
    }
}

public struct ExportedDevice: Codable {
    public let deviceId: String
    public let deviceName: String
    public let pushTokenCount: Int
    public let lastSeenAt: String

    public init(deviceId: String, deviceName: String, pushTokenCount: Int, lastSeenAt: String) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.pushTokenCount = pushTokenCount
        self.lastSeenAt = lastSeenAt
    }
}

public struct ExportedMatch: Codable {
    public let matchId: String
    public let gameDate: String
    public let homeScore: Int?
    public let awayScore: Int?

    public init(matchId: String, gameDate: String, homeScore: Int?, awayScore: Int?) {
        self.matchId = matchId
        self.gameDate = gameDate
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}

// MARK: - API Error Response

public struct APIErrorResponse: Codable, Error {
    public let error: Bool
    public let reason: String
    public let code: String?
    public let timestamp: String

    public init(error: Bool, reason: String, code: String?, timestamp: String) {
        self.error = error
        self.reason = reason
        self.code = code
        self.timestamp = timestamp
    }

    public var errorDate: Date? {
        return ISO8601DateFormatter().date(from: timestamp)
    }
}

// MARK: - Helper Extensions

#if canImport(UIKit)
extension UIDevice {
    /// Get detailed device model identifier (e.g., "iPhone15,3")
    public static var modelIdentifier: String {
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
    public static var deviceName: String {
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
#endif

extension Bundle {
    /// Get app version string
    public var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Get build number
    public var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Get full version string (e.g., "1.0.5 (42)")
    public var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}
