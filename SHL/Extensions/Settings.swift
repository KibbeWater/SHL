//
//  Settings.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 5/10/24.
//

import SwiftUI

public enum SharedPreferenceKeys {
    static let appId = "6479990812"
    static let groupIdentifier: String = "group.kibbewater.shl"
    
    static let POSTHOG_API_KEY = "phc_lPkiCHQ8ZL15IfkCzHRzMaPTv1teimNnfNGrNmpRiPa"
    static let POSTHOG_HOST = "https://eu.i.posthog.com"
}

class Settings: ObservableObject {
    public static let shared = Settings()

    // MARK: - Team Preferences

    @CloudStorage(key: "preferredTeam", default: "")
    private var _preferredTeam: String

    public func getPreferredTeam() -> String? {
        let team = _preferredTeam.isEmpty ? nil : _preferredTeam
        return team
    }

    public func binding_preferredTeam() -> Binding<String> {
        return Binding(
            get: { self._preferredTeam },
            set: { newValue in
                self.objectWillChange.send()
                self._preferredTeam = newValue

                // Sync with backend if user management is enabled
                if self.userManagementEnabled && !newValue.isEmpty {
                    Task {
                        try? await SHLAPIClient.shared.setFavoriteTeam(teamId: newValue)
                    }
                }
            }
        )
    }

    // MARK: - User Management Settings

    @CloudStorage(key: "userManagementEnabled", default: false)
    public var userManagementEnabled: Bool {
        didSet {
            objectWillChange.send()

            // Handle opt-in
            if userManagementEnabled && !oldValue {
                Task {
                    await handleUserManagementOptIn()
                }
            }

            // Handle opt-out
            if !userManagementEnabled && oldValue {
                Task {
                    await handleUserManagementOptOut()
                }
            }
        }
    }

    @CloudStorage(key: "notificationSettings", default: NotificationSettings.default)
    public var notificationSettings: NotificationSettings {
        didSet {
            objectWillChange.send()

            // Sync with backend if user management is enabled
            if userManagementEnabled {
                Task {
                    try? await SHLAPIClient.shared.updateNotificationSettings(notificationSettings)
                }
            }
        }
    }

    // MARK: - User Management Actions

    private func handleUserManagementOptIn() async {
        do {
            // Register user with backend
            let userId = try await AuthenticationManager.shared.register()
            print("User registered successfully: \(userId)")

            // Sync current preferred team to backend
            if let teamId = getPreferredTeam(), !teamId.isEmpty {
                try? await SHLAPIClient.shared.setFavoriteTeam(teamId: teamId)
            }

            // Sync notification settings
            try? await SHLAPIClient.shared.updateNotificationSettings(notificationSettings)

            // Fetch user profile
            try? await AuthenticationManager.shared.fetchUserProfile()

            print("User management opt-in completed")
        } catch {
            print("Failed to opt-in to user management: \(error)")
            // Revert the toggle if registration failed
            await MainActor.run {
                self.userManagementEnabled = false
            }
        }
    }

    private func handleUserManagementOptOut() async {
        do {
            // Logout (invalidates token but keeps local device ID)
            try await AuthenticationManager.shared.logout()
            print("User management opt-out completed")
        } catch {
            print("Failed to opt-out of user management: \(error)")
        }
    }

    // MARK: - Binding Helpers

    public func binding_userManagementEnabled() -> Binding<Bool> {
        return Binding(
            get: { self.userManagementEnabled },
            set: { newValue in
                self.userManagementEnabled = newValue
            }
        )
    }

    public func binding_notificationSettings() -> Binding<NotificationSettings> {
        return Binding(
            get: { self.notificationSettings },
            set: { newValue in
                self.notificationSettings = newValue
            }
        )
    }
}
