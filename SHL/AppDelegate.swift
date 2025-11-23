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
                        try await AuthenticationManager.shared.refreshToken()
                    }
                } catch {
                    print("Failed to initialize user session: \(error)")
                }
            }
        }

        return true
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
}
