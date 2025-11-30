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

        // Observe team changes to re-register tokens with new team code
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterestedTeamsChange),
            name: .interestedTeamsDidChange,
            object: nil
        )
    }

    @objc private func handleInterestedTeamsChange() {
        #if DEBUG
        print("""

        ========== TEAMS CHANGED - RE-REGISTERING TOKENS ==========
        Primary Team Code: \(Settings.shared.getPrimaryTeamCode() ?? "nil")
        Interested Teams: \(Settings.shared.getInterestedTeamIds().count) teams
        Has Push Token: \(pushToken != nil)
        ===========================================================

        """)
        #endif

        Task {
            // Re-register push token with new team code
            if pushToken != nil {
                try? await registerTokenWithBackend()
            }

            // Re-register push-to-start token with new team code
            if #available(iOS 17.2, *) {
                await MainActor.run {
                    ActivityUpdater.shared.startObservingPushToStartToken()
                }
            }
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
        #if DEBUG
        print("📱 Requesting remote notification registration...")
        #endif
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Handle successful APNs token registration
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()

        self.pushToken = tokenString
        self.isRegistered = true

        #if DEBUG
        print("✅ APNs token received: \(tokenString.prefix(20))...")
        #endif

        // Auto-register with backend if user management is enabled
        // Use Settings.shared directly to get current value
        if Settings.shared.userManagementEnabled {
            #if DEBUG
            print("📤 Attempting to register token with backend...")
            #endif
            Task {
                do {
                    try await registerTokenWithBackend()
                } catch {
                    #if DEBUG
                    print("❌ Failed to register token with backend: \(error)")
                    #endif
                }
            }
        } else {
            #if DEBUG
            print("⚠️ User management disabled, skipping backend registration")
            #endif
        }
    }

    /// Handle failed APNs token registration
    func didFailToRegisterForRemoteNotifications(error: Error) {
        #if DEBUG
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        #endif
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
            teamCode: Settings.shared.getPrimaryTeamCode(),
            environment: environment
        )

        #if DEBUG
        print("""

        ========== PUSH TOKEN REGISTRATION ==========
        Token Type: regular
        Token: \(token.prefix(20))...
        Device ID: \(KeychainManager.shared.getDeviceId())
        Primary Team Code: \(Settings.shared.getPrimaryTeamCode() ?? "nil")
        Environment: \(environment)
        =============================================

        """)
        #endif

        #if DEBUG
        print("🌐 Calling API: POST /push-tokens/register")
        #endif

        do {
            let response = try await SHLAPIClient.shared.registerPushToken(request)
            await MainActor.run {
                self.isTokenRegisteredWithBackend = true
            }
            #if DEBUG
            print("✅ Push token registered with backend successfully: \(response)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to register push token with backend: \(error)")
            #endif
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
