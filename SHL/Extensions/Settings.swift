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

    /// Sets all interested teams at once. Existing per-team notification levels are
    /// preserved; newly added teams default to `.off` (onboarding raises the favourite
    /// to `.all`).
    public func setInterestedTeams(_ teams: [InterestedTeam]) {
        objectWillChange.send()
        _interestedTeamIds = teams.map { $0.id }
        _cachedInterestedTeams = teams

        // Reconcile local levels to the new team set, preserving existing choices.
        var levels: [String: String] = [:]
        for team in teams {
            levels[team.id] = _interestedTeamLevels[team.id] ?? TeamNotificationLevel.off.rawValue
        }
        _interestedTeamLevels = levels
        syncTeamCodesToWidgets()

        // Sync with backend if user management is enabled
        if userManagementEnabled {
            let payload = teams.map { team in
                InterestedTeamLevelPayload(teamId: team.id, level: levels[team.id] ?? TeamNotificationLevel.off.rawValue)
            }
            Task {
                _ = try? await SHLAPIClient.shared.setInterestedTeams(payload)
            }
        }

        // Notify observers that teams changed (for token re-registration)
        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    /// Add a team to interested teams (defaults to its current level, or `.off`)
    public func addInterestedTeam(_ team: InterestedTeam) {
        guard !_interestedTeamIds.contains(team.id) else { return }

        objectWillChange.send()
        _interestedTeamIds.append(team.id)
        _cachedInterestedTeams.append(team)
        let level = _interestedTeamLevels[team.id].flatMap { TeamNotificationLevel(rawValue: $0) } ?? .off
        _interestedTeamLevels[team.id] = level.rawValue
        syncTeamCodesToWidgets()

        // Sync with backend if user management is enabled
        if userManagementEnabled {
            Task {
                try? await SHLAPIClient.shared.addInterestedTeam(teamId: team.id, level: level)
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
        _interestedTeamLevels[id] = nil

        // Clear favorite if it was this team
        if _favoriteTeamId == id {
            _favoriteTeamId = nil
        }

        syncTeamCodesToWidgets()

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
        syncTeamCodesToWidgets()
    }

    // MARK: - Widget Preferences Sync

    private static let widgetInterestedCodesKey = "widget_interested_team_codes"
    private static let widgetFavoriteCodeKey = "widget_favorite_team_code"

    /// Syncs team codes to App Group for widget access
    private func syncTeamCodesToWidgets() {
        let defaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier)

        // Write interested team codes
        let codes = _cachedInterestedTeams.map { $0.code }
        defaults?.set(codes, forKey: Self.widgetInterestedCodesKey)

        // Write favorite team code
        let favoriteCode = _cachedInterestedTeams.first(where: { $0.id == _favoriteTeamId })?.code
        defaults?.set(favoriteCode, forKey: Self.widgetFavoriteCodeKey)

        #if DEBUG
        print("✅ Synced team codes to widgets: \(codes), favorite: \(favoriteCode ?? "none")")
        #endif
    }

    /// Returns the primary team code (first team) for push token registration
    public func getPrimaryTeamCode() -> String? {
        return _cachedInterestedTeams.first?.code
    }

    /// Check if a specific team is in interested teams
    public func isTeamInterested(teamId: String) -> Bool {
        return _interestedTeamIds.contains(teamId)
    }

    // MARK: - Per-Team Notification Levels

    /// Per-team notification level keyed by team id (raw `TeamNotificationLevel` value).
    /// Mirrors the backend's `notify_level`; hydrated from the backend on launch.
    @CloudStorage(key: "interestedTeamLevels", default: [:])
    private var _interestedTeamLevels: [String: String]

    /// The notification level for a team (`.off` if unset).
    public func notificationLevel(for teamId: String) -> TeamNotificationLevel {
        guard let raw = _interestedTeamLevels[teamId],
              let level = TeamNotificationLevel(rawValue: raw) else {
            return .off
        }
        return level
    }

    /// Sets a team's notification level locally and syncs it to the backend.
    public func setNotificationLevel(_ level: TeamNotificationLevel, for teamId: String) {
        objectWillChange.send()
        _interestedTeamLevels[teamId] = level.rawValue

        if userManagementEnabled {
            Task {
                _ = try? await SHLAPIClient.shared.updateTeamNotificationLevel(teamId: teamId, level: level)
            }
        }
    }

    /// Merges backend-provided levels into local storage (backend is the source of truth).
    public func cacheInterestedTeamLevels(_ levels: [String: String]) {
        guard !levels.isEmpty else { return }
        objectWillChange.send()
        var merged = _interestedTeamLevels
        for (teamId, raw) in levels {
            merged[teamId] = raw
        }
        _interestedTeamLevels = merged
    }

    /// Assigns default levels to any interested team that doesn't have one yet:
    /// the favourite team gets `.all`, everything else `.off`. Used when first
    /// enabling account features for a previously opted-out user.
    private func ensureDefaultLevelsForCurrentTeams() {
        var levels = _interestedTeamLevels
        for id in _interestedTeamIds where levels[id] == nil {
            levels[id] = (id == _favoriteTeamId ? TeamNotificationLevel.all : .off).rawValue
        }
        _interestedTeamLevels = levels
    }

    /// Pulls interested teams and their levels from the backend into the local cache.
    /// Backend is authoritative for levels (it holds the migration backfill), so this
    /// must run before the UI lets the user edit teams/levels.
    public func hydrateInterestedTeamsFromBackend() async {
        guard userManagementEnabled else { return }
        guard let response = try? await SHLAPIClient.shared.getInterestedTeams() else { return }
        await MainActor.run {
            self.cacheInterestedTeams(response.teamsWithLevels)
            self.cacheInterestedTeamLevels(response.levels ?? [:])
        }
    }

    // MARK: - Favorite Team

    @CloudStorage(key: "favoriteTeamId", default: nil)
    private var _favoriteTeamId: String?

    /// Returns the favorite team ID (UUID)
    public func getFavoriteTeamId() -> String? {
        return _favoriteTeamId
    }

    /// Sets the favorite team ID
    public func setFavoriteTeamId(_ id: String?) {
        objectWillChange.send()
        _favoriteTeamId = id

        // If favorite team is set but not in interested teams, clear it
        if let id = id, !_interestedTeamIds.contains(id) {
            _favoriteTeamId = nil
        }

        syncTeamCodesToWidgets()
    }

    /// Returns the favorite team with full details
    public func getFavoriteTeam() -> InterestedTeam? {
        guard let favoriteId = _favoriteTeamId else { return nil }
        return _cachedInterestedTeams.first(where: { $0.id == favoriteId })
    }

    /// Binding helper for favorite team ID
    public func binding_favoriteTeamId() -> Binding<String?> {
        return Binding(
            get: { self.getFavoriteTeamId() },
            set: { newValue in
                self.setFavoriteTeamId(newValue)
            }
        )
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

    // MARK: - Onboarding

    @CloudStorage(key: "hasCompletedOnboarding", default: false)
    public var hasCompletedOnboarding: Bool {
        didSet {
            objectWillChange.send()
        }
    }

    public func completeOnboarding() {
        objectWillChange.send()
        hasCompletedOnboarding = true
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

    /// Account features (anonymous device account, cross-device sync, push notifications)
    /// are always on. Defaults to `true`; `forceEnableAccountFeaturesIfNeeded()` also
    /// flips any user who previously opted out.
    @CloudStorage(key: "userManagementEnabled", default: true)
    public var userManagementEnabled: Bool {
        didSet {
            objectWillChange.send()

            // Register + sync when turned on (e.g. the one-time migration for older users).
            if userManagementEnabled && !oldValue {
                Task {
                    await handleUserManagementOptIn()
                }
            }
        }
    }

    /// Guards the one-time migration that makes account features always-on.
    @CloudStorage(key: "didForceEnableAccountFeatures", default: false)
    private var didForceEnableAccountFeatures: Bool

    /// One-time migration: account features are now mandatory. Flip any user who was
    /// previously opted out (stored `false`) to `true`, registering them via `didSet`.
    public func forceEnableAccountFeaturesIfNeeded() {
        guard !didForceEnableAccountFeatures else { return }
        didForceEnableAccountFeatures = true
        if !userManagementEnabled {
            userManagementEnabled = true
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

            // This path runs for previously opted-out users (backend has no teams for
            // them yet), so apply the favourite-only defaults and push local teams up.
            await MainActor.run { self.ensureDefaultLevelsForCurrentTeams() }
            let teamIds = getInterestedTeamIds()
            if !teamIds.isEmpty {
                let payload = teamIds.map { id in
                    InterestedTeamLevelPayload(teamId: id, level: notificationLevel(for: id).rawValue)
                }
                _ = try? await SHLAPIClient.shared.setInterestedTeams(payload)
            }

            // Sync notification settings
            try? await SHLAPIClient.shared.updateNotificationSettings(notificationSettings)

            // Fetch user profile
            try? await AuthenticationManager.shared.fetchUserProfile()

            print("Account features initialized")
        } catch {
            // Account features are always-on; if registration fails we keep the flag set
            // and AppDelegate retries registration on the next launch / activation.
            print("Failed to initialize account features: \(error)")
        }
    }

    // MARK: - Existing-User Notification Prompt

    /// Whether the one-time "turn on notifications" prompt has been shown to a user who
    /// updated from a version without the notifications onboarding step. New users go
    /// through onboarding and have this set on completion.
    @CloudStorage(key: "hasPromptedExistingUserNotifications", default: false)
    public var hasPromptedExistingUserNotifications: Bool {
        didSet {
            objectWillChange.send()
        }
    }

    // MARK: - Backend Sync

    /// Ensures the device is registered, then pushes the local interested teams (with
    /// their levels) and notification settings to the backend. Used after onboarding so a
    /// brand-new user's choices reach the server once authentication is ready.
    public func syncAllPreferencesToBackend() async {
        guard userManagementEnabled else { return }
        if !AuthenticationManager.shared.hasValidToken {
            _ = try? await AuthenticationManager.shared.register()
        }
        let teamIds = getInterestedTeamIds()
        if !teamIds.isEmpty {
            let payload = teamIds.map { id in
                InterestedTeamLevelPayload(teamId: id, level: notificationLevel(for: id).rawValue)
            }
            _ = try? await SHLAPIClient.shared.setInterestedTeams(payload)
        }
        _ = try? await SHLAPIClient.shared.updateNotificationSettings(notificationSettings)
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
