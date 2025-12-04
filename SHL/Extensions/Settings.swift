//
//  Settings.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 5/10/24.
//

import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let interestedTeamsDidChange = Notification.Name("interestedTeamsDidChange")
    static let iCloudQuotaExceeded = Notification.Name("iCloudQuotaExceeded")
    static let iCloudNotAuthenticated = Notification.Name("iCloudNotAuthenticated")
    static let userManagementInitializationFailed = Notification.Name("userManagementInitializationFailed")
}

public enum SharedPreferenceKeys {
    static let appId = "6479990812"
    static let groupIdentifier: String = "group.kibbewater.shl"
    
    static let POSTHOG_API_KEY = "phc_lPkiCHQ8ZL15IfkCzHRzMaPTv1teimNnfNGrNmpRiPa"
    static let POSTHOG_HOST = "https://eu.i.posthog.com"
}

class Settings: ObservableObject {
    public static let shared = Settings()

    // MARK: - Interested Teams

    @CloudStorage(key: "interestedTeamIds", default: [])
    private var _interestedTeamIds: [String]

    // Cache for team details (not synced to cloud - fetched dynamically)
    private var _cachedInterestedTeams: [InterestedTeam] = []

    /// Returns the interested team IDs (UUIDs)
    public func getInterestedTeamIds() -> [String] {
        return _interestedTeamIds
    }

    /// Returns the cached interested teams with full details
    public func getInterestedTeams() -> [InterestedTeam] {
        return _cachedInterestedTeams
    }

    /// Sets all interested teams at once
    public func setInterestedTeams(_ teams: [InterestedTeam]) {
        objectWillChange.send()
        _interestedTeamIds = teams.map { $0.id }
        _cachedInterestedTeams = teams

        // Sync with backend if user management is enabled
        if userManagementEnabled {
            Task {
                try? await SHLAPIClient.shared.setInterestedTeams(teamIds: _interestedTeamIds)
            }
        }

        // Notify observers that teams changed (for token re-registration)
        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    /// Add a team to interested teams
    public func addInterestedTeam(_ team: InterestedTeam) {
        guard !_interestedTeamIds.contains(team.id) else { return }

        objectWillChange.send()
        _interestedTeamIds.append(team.id)
        _cachedInterestedTeams.append(team)

        // Sync with backend if user management is enabled
        if userManagementEnabled {
            Task {
                try? await SHLAPIClient.shared.addInterestedTeam(teamId: team.id)
            }
        }

        // Notify observers that teams changed
        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    /// Remove a team from interested teams
    public func removeInterestedTeam(id: String) {
        objectWillChange.send()
        _interestedTeamIds.removeAll { $0 == id }
        _cachedInterestedTeams.removeAll { $0.id == id }

        // Sync with backend if user management is enabled
        if userManagementEnabled {
            Task {
                try? await SHLAPIClient.shared.removeInterestedTeam(teamId: id)
            }
        }

        // Notify observers that teams changed
        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    /// Cache interested teams from API response (without triggering sync)
    public func cacheInterestedTeams(_ teams: [InterestedTeam]) {
        objectWillChange.send()
        _cachedInterestedTeams = teams
        _interestedTeamIds = teams.map { $0.id }
    }

    /// Returns the primary team code (first team) for push token registration
    public func getPrimaryTeamCode() -> String? {
        return _cachedInterestedTeams.first?.code
    }

    /// Check if a specific team is in interested teams
    public func isTeamInterested(teamId: String) -> Bool {
        return _interestedTeamIds.contains(teamId)
    }

    // MARK: - Migration from old preferredTeam

    /// Migrate old single preferredTeam to new interestedTeams array (call once on app launch)
    public func migratePreferredTeamIfNeeded() {
        let oldKey = "preferredTeam"
        let defaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier)

        if let oldTeamId = defaults?.string(forKey: oldKey), !oldTeamId.isEmpty {
            // Only migrate if we don't already have interested teams
            if _interestedTeamIds.isEmpty {
                _interestedTeamIds = [oldTeamId]
                #if DEBUG
                print("✅ Migrated preferredTeam to interestedTeams: \(oldTeamId)")
                #endif
            }
            // Clear old key
            defaults?.removeObject(forKey: oldKey)
        }
    }

    // MARK: - Security Settings

    /// Controls whether authentication tokens sync to iCloud Keychain across devices
    /// Default: true (opt-in for convenience and security)
    @CloudStorage(key: "keychainSyncEnabled", default: true)
    public var keychainSyncEnabled: Bool {
        didSet {
            objectWillChange.send()
        }
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

            // Sync current interested teams to backend
            let teamIds = getInterestedTeamIds()
            if !teamIds.isEmpty {
                try? await SHLAPIClient.shared.setInterestedTeams(teamIds: teamIds)
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

    public func binding_keychainSyncEnabled() -> Binding<Bool> {
        return Binding(
            get: { self.keychainSyncEnabled },
            set: { newValue in
                self.keychainSyncEnabled = newValue
            }
        )
    }
}
