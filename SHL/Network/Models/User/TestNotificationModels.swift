//
//  TestNotificationModels.swift
//  SHL
//
//  Created by Claude Code
//

#if DEBUG
import Foundation

// MARK: - Test Notification Request

struct TestNotificationRequest: Codable {
    let type: String
    let title: String?
    let subtitle: String?
    let body: String?
    let badge: Int?
    let customData: [String: String]?
    let matchId: String?
    let bypassPreferences: Bool?
    let bypassCache: Bool?
    let environment: String?

    init(
        type: NotificationType,
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil,
        badge: Int? = nil,
        customData: [String: String]? = nil,
        matchId: String? = nil,
        bypassPreferences: Bool? = true,
        bypassCache: Bool? = true,
        environment: String? = nil
    ) {
        self.type = type.rawValue
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.badge = badge
        self.customData = customData
        self.matchId = matchId
        self.bypassPreferences = bypassPreferences
        self.bypassCache = bypassCache
        self.environment = environment
    }
}

// MARK: - Test Notification Response

struct TestNotificationResponse: Codable {
    let userId: String
    let testMode: String
    let tokensFound: Int
    let tokensSent: Int
    let results: [TokenResult]

    struct TokenResult: Codable {
        let tokenId: String?
        let environment: String
        let success: Bool
        let error: String?
    }

    var successCount: Int {
        results.filter { $0.success }.count
    }

    var failureCount: Int {
        results.filter { !$0.success }.count
    }

    var isFullSuccess: Bool {
        tokensSent == tokensFound && failureCount == 0
    }

    var isPartialSuccess: Bool {
        successCount > 0 && failureCount > 0
    }

    var summary: String {
        if isFullSuccess {
            return "Successfully sent to all \(tokensSent) device(s)"
        } else if isPartialSuccess {
            return "Sent to \(successCount)/\(tokensFound) device(s)"
        } else {
            return "Failed to send to any devices"
        }
    }
}

// MARK: - Notification Type

enum NotificationType: String, CaseIterable, Codable {
    case custom = "custom"
    case pregame = "pregame"
    case goal = "goal"
    case finalScore = "finalScore"

    var displayName: String {
        switch self {
        case .custom:
            return "Custom"
        case .pregame:
            return "Pre-Game (15 min)"
        case .goal:
            return "Goal Scored"
        case .finalScore:
            return "Final Score"
        }
    }

    var icon: String {
        switch self {
        case .custom:
            return "bell.fill"
        case .pregame:
            return "clock.fill"
        case .goal:
            return "sportscourt.fill"
        case .finalScore:
            return "flag.checkered"
        }
    }

    var description: String {
        switch self {
        case .custom:
            return "Send a custom notification with your own title and message"
        case .pregame:
            return "Simulates a 15-minute match start warning"
        case .goal:
            return "Simulates a goal scored notification"
        case .finalScore:
            return "Simulates a final score notification"
        }
    }
}

#endif
