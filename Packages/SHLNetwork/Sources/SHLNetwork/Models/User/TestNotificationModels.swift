//
//  TestNotificationModels.swift
//  SHL
//
//  Created by Claude Code
//

#if DEBUG
import Foundation

// MARK: - Test Notification Request

public struct TestNotificationRequest: Codable {
    public let type: String
    public let title: String?
    public let subtitle: String?
    public let body: String?
    public let badge: Int?
    public let customData: [String: String]?
    public let matchId: String?
    public let bypassPreferences: Bool?
    public let bypassCache: Bool?
    public let environment: String?

    public init(
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

public struct TestNotificationResponse: Codable {
    public let userId: String
    public let testMode: String
    public let tokensFound: Int
    public let tokensSent: Int
    public let results: [TokenResult]

    public struct TokenResult: Codable {
        public let tokenId: String?
        public let environment: String
        public let success: Bool
        public let error: String?

        public init(tokenId: String?, environment: String, success: Bool, error: String?) {
            self.tokenId = tokenId
            self.environment = environment
            self.success = success
            self.error = error
        }
    }

    public init(userId: String, testMode: String, tokensFound: Int, tokensSent: Int, results: [TokenResult]) {
        self.userId = userId
        self.testMode = testMode
        self.tokensFound = tokensFound
        self.tokensSent = tokensSent
        self.results = results
    }

    public var successCount: Int {
        results.filter { $0.success }.count
    }

    public var failureCount: Int {
        results.filter { !$0.success }.count
    }

    public var isFullSuccess: Bool {
        tokensSent == tokensFound && failureCount == 0
    }

    public var isPartialSuccess: Bool {
        successCount > 0 && failureCount > 0
    }

    public var summary: String {
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

public enum NotificationType: String, CaseIterable, Codable {
    case custom = "custom"
    case pregame = "pregame"
    case goal = "goal"
    case finalScore = "finalScore"

    public var displayName: String {
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

    public var icon: String {
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

    public var description: String {
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
