//
//  PushNotificationManager.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation
import UserNotifications
import UIKit

/// Manager for handling push notifications and APNs token registration
final class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    @Published private(set) var isRegistered = false
    @Published private(set) var pushToken: String?
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var isTokenRegisteredWithBackend = false

    private let settings = Settings.shared

    private override init() {
        super.init()
        Task {
            await checkAndUpdatePermissionStatus()
        }
    }

    // MARK: - Permission Requests

    /// Request notification permission from user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Check current notification permission status
    func checkNotificationPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Check and update permission status
    func checkAndUpdatePermissionStatus() async {
        let status = await checkNotificationPermission()
        await MainActor.run {
            self.permissionStatus = status
        }
    }

    /// Request permissions and register token with backend
    /// Convenience method callable from anywhere in the app
    func requestPermissionsAndRegister() async -> Bool {
        let granted = await requestNotificationPermission()

        if granted {
            await checkAndUpdatePermissionStatus()
            // Token registration will happen after token is received
            // See didRegisterForRemoteNotifications
        }

        return granted
    }

    // MARK: - APNs Registration

    /// Register for remote notifications (call from main thread)
    @MainActor
    func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Handle successful APNs token registration
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()

        self.pushToken = tokenString
        self.isRegistered = true

        print("Successfully registered for remote notifications. Token: \(tokenString)")

        // Auto-register with backend if user management is enabled
        if settings.userManagementEnabled {
            Task {
                try? await registerTokenWithBackend()
            }
        }
    }

    /// Handle failed APNs token registration
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("Failed to register for remote notifications: \(error)")
        self.isRegistered = false
    }

    /// Register token with backend for push notifications
    func registerTokenWithBackend() async throws {
        guard let token = pushToken else {
            throw PushNotificationError.noToken
        }

        guard settings.userManagementEnabled else {
            throw PushNotificationError.userManagementDisabled
        }

        #if DEBUG
        let environment = "development"
        #else
        let environment = "production"
        #endif

        let request = RegisterPushTokenRequest(
            token: token,
            deviceId: KeychainManager.shared.getDeviceId(),
            type: "regular",
            environment: environment
        )

        do {
            let _ = try await SHLAPIClient.shared.registerPushToken(request)
            await MainActor.run {
                self.isTokenRegisteredWithBackend = true
            }
            print("✅ Push token registered with backend successfully")
        } catch {
            print("❌ Failed to register push token with backend: \(error)")
            throw error
        }
    }

    // MARK: - Live Activity Token Registration

    /// Register push token for live match updates
    func registerLiveActivityToken(matchUUID: String) async throws {
        guard let token = pushToken else {
            throw PushNotificationError.noToken
        }

        guard settings.userManagementEnabled else {
            throw PushNotificationError.userManagementDisabled
        }

        do {
            let response = try await SHLAPIClient.shared.registerLiveActivityToken(
                matchUUID: matchUUID,
                token: token
            )

            print("Successfully registered live activity token for match: \(matchUUID)")
        } catch {
            print("Failed to register live activity token: \(error)")
            throw error
        }
    }

    // MARK: - Notification Handling

    /// Handle received remote notification
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("Received remote notification: \(userInfo)")

        // Extract notification type and data
        guard let notificationType = userInfo["type"] as? String else {
            return
        }

        switch notificationType {
        case "match_start":
            handleMatchStartNotification(userInfo)
        case "goal":
            handleGoalNotification(userInfo)
        case "period_end":
            handlePeriodEndNotification(userInfo)
        case "final_score":
            handleFinalScoreNotification(userInfo)
        default:
            print("Unknown notification type: \(notificationType)")
        }
    }

    private func handleMatchStartNotification(_ userInfo: [AnyHashable: Any]) {
        print("Match started notification")
        // Handle match start notification
        // You can post a notification or update UI here
    }

    private func handleGoalNotification(_ userInfo: [AnyHashable: Any]) {
        print("Goal notification")
        // Handle goal notification
    }

    private func handlePeriodEndNotification(_ userInfo: [AnyHashable: Any]) {
        print("Period end notification")
        // Handle period end notification
    }

    private func handleFinalScoreNotification(_ userInfo: [AnyHashable: Any]) {
        print("Final score notification")
        // Handle final score notification
    }
}

// MARK: - Push Notification Errors

enum PushNotificationError: LocalizedError {
    case noToken
    case userManagementDisabled
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No push notification token available"
        case .userManagementDisabled:
            return "User management must be enabled to use push notifications"
        case .registrationFailed:
            return "Failed to register for push notifications"
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension PushNotificationManager {
    /// Send a test notification (Debug Only)
    func testNotification(type: NotificationType, title: String? = nil, body: String? = nil) async throws -> TestNotificationResponse {
        guard AuthenticationManager.shared.isAuthenticated else {
            throw PushNotificationError.userManagementDisabled
        }

        let request: TestNotificationRequest
        if type == .custom {
            request = TestNotificationRequest(
                type: type,
                title: title ?? "Test",
                body: body ?? "Test notification",
                bypassPreferences: true,
                bypassCache: true
            )
        } else {
            request = TestNotificationRequest(
                type: type,
                bypassPreferences: true,
                bypassCache: true
            )
        }

        // Backend uses JWT to identify user automatically
        return try await SHLAPIClient.shared.testNotification(request: request)
    }

    /// Get detailed push token information for debugging
    var debugInfo: String {
        var info = "Push Notification Debug Info\n"
        info += "============================\n\n"

        if let token = pushToken {
            info += "Token: \(token.prefix(20))...\n"
        } else {
            info += "Token: None\n"
        }

        info += "Registered: \(isRegistered)\n"

        if let userId = AuthenticationManager.shared.currentUserId {
            info += "User ID: \(userId)\n"
        } else {
            info += "User ID: Not authenticated\n"
        }

        info += "User Management: \(Settings.shared.userManagementEnabled ? "Enabled" : "Disabled")\n"

        return info
    }
}
#endif
