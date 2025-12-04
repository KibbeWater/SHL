//
//  AppDelegate.swift
//  SHL
//
//  Created by Claude Code
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Migrate from old single preferredTeam to new interestedTeams array (one-time migration)
        Settings.shared.migratePreferredTeamIfNeeded()

        // Check if user has opted in to user management
        if Settings.shared.userManagementEnabled {
            // Try to sync with iCloud session
            Task {
                do {
                    let synced = try await AuthenticationManager.shared.syncWithiCloud()
                    if !synced {
                        // No iCloud session found, check if we have local session
                        if !AuthenticationManager.shared.hasValidToken {
                            // Register new user
                            _ = try await AuthenticationManager.shared.register()
                        }
                    }

                    // Check if token needs refresh
                    if KeychainManager.shared.isTokenExpiringSoon() {
                        do {
                            try await AuthenticationManager.shared.refreshToken()
                        } catch {
                            #if DEBUG
                            print("⚠️ Token refresh failed, attempting re-registration: \(error)")
                            #endif
                            // Token refresh failed (likely user doesn't exist), re-register
                            _ = try await AuthenticationManager.shared.register()
                        }
                    }

                    // Fetch team code before registering push tokens
                    await Self.fetchAndCacheInterestedTeams()

                    // Register for push notifications on launch
                    await PushNotificationManager.shared.registerForRemoteNotifications()
                } catch {
                    // Log detailed error for debugging
                    #if DEBUG
                    print("❌ Failed to initialize user session: \(error.localizedDescription)")
                    print("   Error details: \(error)")
                    #endif

                    // Post notification that user management is unavailable
                    // This allows other parts of the app to handle degraded functionality
                    NotificationCenter.default.post(
                        name: .userManagementInitializationFailed,
                        object: nil,
                        userInfo: ["error": error]
                    )

                    // App continues to function with degraded capabilities
                    // Push notifications and cross-device sync will be unavailable
                }
            }

            // Start observing push-to-start token on first launch (iOS 17.2+)
            if #available(iOS 17.2, *) {
                Task { @MainActor in
                    // Fetch team code first, then start observing
                    await Self.fetchAndCacheInterestedTeams()
                    ActivityUpdater.shared.startObservingPushToStartToken()
                }
            }
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Re-register tokens when app becomes active
        Task {
            // Re-register regular push token
            if Settings.shared.userManagementEnabled {
                await PushNotificationManager.shared.registerForRemoteNotifications()

                // Also register with backend if we already have a token
                if PushNotificationManager.shared.pushToken != nil {
                    try? await PushNotificationManager.shared.registerTokenWithBackend()
                }
            }

            // Re-register push-to-start token (iOS 17.2+)
            if #available(iOS 17.2, *) {
                await MainActor.run {
                    ActivityUpdater.shared.startObservingPushToStartToken()
                }
            }
        }
    }

    // MARK: - Push Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        PushNotificationManager.shared.handleRemoteNotification(userInfo: userInfo)

        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        PushNotificationManager.shared.handleRemoteNotification(userInfo: userInfo)

        // Handle notification tap action here
        // For example, navigate to match detail if it's a match notification

        completionHandler()
    }

    // MARK: - Helper Methods

    /// Fetch teams and cache interested team details for push token registration
    private static func fetchAndCacheInterestedTeams() async {
        let interestedIds = Settings.shared.getInterestedTeamIds()
        guard !interestedIds.isEmpty else {
            return
        }

        // Skip if already cached
        if !Settings.shared.getInterestedTeams().isEmpty {
            return
        }

        do {
            let teams = try await SHLAPIClient.shared.getTeams()
            let cachedTeams = interestedIds.compactMap { id in
                teams.first(where: { $0.id == id }).map { team in
                    InterestedTeam(id: team.id, name: team.name, code: team.code, city: nil)
                }
            }
            Settings.shared.cacheInterestedTeams(cachedTeams)
            #if DEBUG
            print("✅ Cached \(cachedTeams.count) interested teams")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to fetch teams for caching: \(error.localizedDescription)")
            #endif
        }
    }
}
