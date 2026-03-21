//
//  PushNotificationManager.swift
//  SHL
//
//  Created by Claude Code
//

#if os(iOS)
import Foundation
import UserNotifications
import UIKit
import SHLNetwork

/// Manager for handling push notifications and APNs token registration
public final class PushNotificationManager: NSObject, ObservableObject {
    public static let shared = PushNotificationManager()

    @Published public private(set) var isRegistered = false
    @Published public private(set) var pushToken: String?
    @Published public var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published public var isTokenRegisteredWithBackend = false

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
    public func requestNotificationPermission() async -> Bool {
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
    public func checkNotificationPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Check and update permission status
    public func checkAndUpdatePermissionStatus() async {
        let status = await checkNotificationPermission()
        await MainActor.run {
            self.permissionStatus = status
        }
    }

    /// Request permissions and register token with backend
    /// Convenience method callable from anywhere in the app
    public func requestPermissionsAndRegister() async -> Bool {
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
    public func registerForRemoteNotifications() async {
        #if DEBUG
        print("📱 Requesting remote notification registration...")
        #endif
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Handle successful APNs token registration
    public func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()

        self.pushToken = tokenString
        self.isRegistered = true

        #if DEBUG
        print("✅ APNs token received: [REDACTED]")
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
    public func didFailToRegisterForRemoteNotifications(error: Error) {
        #if DEBUG
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        #endif
        self.isRegistered = false
    }

    /// Register token with backend for push notifications
    public func registerTokenWithBackend() async throws {
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
        Token: [REDACTED]
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
    public func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
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

    // MARK: - Notification Handler Stubs

    /// Callback for navigating to a match from a notification
    /// Set this from the app layer to provide navigation behavior
    public var onNavigateToMatch: ((_ matchId: String, _ source: String) -> Void)?

    private func handleMatchStartNotification(_ userInfo: [AnyHashable: Any]) {
        guard let matchId = userInfo["matchId"] as? String else { return }
        Task { @MainActor in
            onNavigateToMatch?(matchId, "push_match_start")
        }
    }

    private func handleGoalNotification(_ userInfo: [AnyHashable: Any]) {
        guard let matchId = userInfo["matchId"] as? String else { return }
        Task { @MainActor in
            onNavigateToMatch?(matchId, "push_goal")
        }
    }

    private func handlePeriodEndNotification(_ userInfo: [AnyHashable: Any]) {
        guard let matchId = userInfo["matchId"] as? String else { return }
        Task { @MainActor in
            onNavigateToMatch?(matchId, "push_period_end")
        }
    }

    private func handleFinalScoreNotification(_ userInfo: [AnyHashable: Any]) {
        guard let matchId = userInfo["matchId"] as? String else { return }
        Task { @MainActor in
            onNavigateToMatch?(matchId, "push_final_score")
        }
    }
}

// MARK: - Push Notification Errors

public enum PushNotificationError: LocalizedError {
    case noToken
    case userManagementDisabled
    case registrationFailed

    public var errorDescription: String? {
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
    public func testNotification(type: NotificationType, title: String? = nil, body: String? = nil) async throws -> TestNotificationResponse {
        guard await AuthenticationManager.shared.isAuthenticated else {
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
    public var debugInfo: String {
        var info = "Push Notification Debug Info\n"
        info += "============================\n\n"

        if pushToken != nil {
            info += "Token: [REDACTED]\n"
        } else {
            info += "Token: None\n"
        }

        info += "Registered: \(isRegistered)\n"

        info += "User ID: (check AuthenticationManager)\n"

        info += "User Management: \(Settings.shared.userManagementEnabled ? "Enabled" : "Disabled")\n"

        return info
    }
}
#endif
#endif // os(iOS)
