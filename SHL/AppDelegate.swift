//
//  AppDelegate.swift
//  SHL
//
//  Created by Claude Code
//

import SHLCore
import SHLNetwork
import UIKit
import UserNotifications
import PostHog

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Migrate from old single preferredTeam to new interestedTeams array (one-time migration)
        Settings.shared.migratePreferredTeamIfNeeded()

        // Populate team color cache for widgets
        Self.populateTeamColorCache()

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

                    // Set up analytics callback for activity starts
                    ActivityUpdater.shared.onActivityStarted = { matchId, homeTeam, awayTeam in
                        PostHogSDK.shared.capture(
                            "started_live_activity",
                            properties: [
                                "join_type": "push_to_start",
                                "match_id": matchId,
                                "home_team": homeTeam,
                                "away_team": awayTeam
                            ]
                        )
                    }

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
        let identifier = response.notification.request.identifier

        // Check for matchId in userInfo (works for both push and local notifications)
        if let matchId = userInfo["matchId"] as? String {
            Task { @MainActor in
                NavigationCoordinator.shared.navigateToMatch(id: matchId, source: "notification_tap")
            }
        } else if userInfo["type"] == nil {
            // Fallback for old local notifications: identifier IS the match ID
            Task { @MainActor in
                NavigationCoordinator.shared.navigateToMatch(id: identifier, source: "local_reminder")
            }
        }

        // Still call original handler for any additional processing
        PushNotificationManager.shared.handleRemoteNotification(userInfo: userInfo)

        completionHandler()
    }

    // MARK: - Helper Methods

    /// Populate shared team color cache for widgets
    private static func populateTeamColorCache() {
        let teamCodes = [
            "BIF", "DIF", "FBK", "FHC", "HV71", "IKO", "LHC", "LHF",
            "LIF", "MIF", "MODO", "OHK", "ÖRE", "RBK", "SAIK", "SKE",
            "TIK", "VLH"
        ]

        for code in teamCodes {
            // Skip if already cached
            guard !SharedTeamColorCache.shared.hasColor(forTeamCode: code) else { continue }

            let teamKey = "Team/\(code)"
            if let teamImage = UIImage(named: teamKey) {
                // Check memory/disk cache first
                if let cachedColor = ColorCache.shared.getColor(forKey: teamKey) {
                    SharedTeamColorCache.shared.cacheColor(cachedColor, forTeamCode: code)
                } else {
                    // Extract color from image
                    teamImage.getColors(quality: .low) { colors in
                        if let bgColor = colors?.background {
                            ColorCache.shared.cacheColor(bgColor, forKey: teamKey)
                            SharedTeamColorCache.shared.cacheColor(bgColor, forTeamCode: code)
                        }
                    }
                }
            }
        }

        #if DEBUG
        print("✅ Team color cache populated: \(SharedTeamColorCache.shared.cachedTeamCodes.count) teams")
        #endif
    }

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
