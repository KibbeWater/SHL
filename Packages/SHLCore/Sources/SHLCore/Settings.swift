//
//  Settings.swift
//  SHLCore
//

import SwiftUI
import SHLNetwork

// MARK: - Notification Names

public extension Notification.Name {
    static let interestedTeamsDidChange = Notification.Name("interestedTeamsDidChange")
    static let iCloudQuotaExceeded = Notification.Name("iCloudQuotaExceeded")
    static let iCloudNotAuthenticated = Notification.Name("iCloudNotAuthenticated")
    static let userManagementInitializationFailed = Notification.Name("userManagementInitializationFailed")
}

public enum SharedPreferenceKeys {
    public static let appId = "6479990812"
    public static let groupIdentifier: String = "group.kibbewater.shl"

    public static let POSTHOG_API_KEY = "phc_lPkiCHQ8ZL15IfkCzHRzMaPTv1teimNnfNGrNmpRiPa"
    public static let POSTHOG_HOST = "https://eu.i.posthog.com"
}

public class Settings: ObservableObject {
    public static let shared = Settings()

    /// Closure for API calls — injected by the app layer to avoid direct SHLAPIClient coupling
    public var apiClient: SHLAPIClient?

    // MARK: - Interested Teams

    @CloudStorage(key: "interestedTeamIds", default: [])
    private var _interestedTeamIds: [String]

    private var _cachedInterestedTeams: [InterestedTeam] = []

    public func getInterestedTeamIds() -> [String] {
        return _interestedTeamIds
    }

    public func getInterestedTeams() -> [InterestedTeam] {
        return _cachedInterestedTeams
    }

    public func setInterestedTeams(_ teams: [InterestedTeam]) {
        objectWillChange.send()
        _interestedTeamIds = teams.map { $0.id }
        _cachedInterestedTeams = teams
        syncTeamCodesToWidgets()

        if userManagementEnabled, let api = apiClient {
            Task {
                try? await api.setInterestedTeams(teamIds: self._interestedTeamIds)
            }
        }

        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    public func addInterestedTeam(_ team: InterestedTeam) {
        guard !_interestedTeamIds.contains(team.id) else { return }

        objectWillChange.send()
        _interestedTeamIds.append(team.id)
        _cachedInterestedTeams.append(team)
        syncTeamCodesToWidgets()

        if userManagementEnabled, let api = apiClient {
            Task {
                try? await api.addInterestedTeam(teamId: team.id)
            }
        }

        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    public func removeInterestedTeam(id: String) {
        objectWillChange.send()
        _interestedTeamIds.removeAll { $0 == id }
        _cachedInterestedTeams.removeAll { $0.id == id }

        if _favoriteTeamId == id {
            _favoriteTeamId = nil
        }

        syncTeamCodesToWidgets()

        if userManagementEnabled, let api = apiClient {
            Task {
                try? await api.removeInterestedTeam(teamId: id)
            }
        }

        NotificationCenter.default.post(name: .interestedTeamsDidChange, object: nil)
    }

    public func cacheInterestedTeams(_ teams: [InterestedTeam]) {
        objectWillChange.send()
        _cachedInterestedTeams = teams
        _interestedTeamIds = teams.map { $0.id }
        syncTeamCodesToWidgets()
    }

    // MARK: - Widget Preferences Sync

    private static let widgetInterestedCodesKey = "widget_interested_team_codes"
    private static let widgetFavoriteCodeKey = "widget_favorite_team_code"

    private func syncTeamCodesToWidgets() {
        let defaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier)
        let codes = _cachedInterestedTeams.map { $0.code }
        defaults?.set(codes, forKey: Self.widgetInterestedCodesKey)
        let favoriteCode = _cachedInterestedTeams.first(where: { $0.id == _favoriteTeamId })?.code
        defaults?.set(favoriteCode, forKey: Self.widgetFavoriteCodeKey)
    }

    public func getPrimaryTeamCode() -> String? {
        return _cachedInterestedTeams.first?.code
    }

    public func isTeamInterested(teamId: String) -> Bool {
        return _interestedTeamIds.contains(teamId)
    }

    // MARK: - Favorite Team

    @CloudStorage(key: "favoriteTeamId", default: nil)
    private var _favoriteTeamId: String?

    public func getFavoriteTeamId() -> String? {
        return _favoriteTeamId
    }

    public func setFavoriteTeamId(_ id: String?) {
        objectWillChange.send()
        _favoriteTeamId = id
        if let id = id, !_interestedTeamIds.contains(id) {
            _favoriteTeamId = nil
        }
        syncTeamCodesToWidgets()
    }

    public func getFavoriteTeam() -> InterestedTeam? {
        guard let favoriteId = _favoriteTeamId else { return nil }
        return _cachedInterestedTeams.first(where: { $0.id == favoriteId })
    }

    public func binding_favoriteTeamId() -> Binding<String?> {
        return Binding(
            get: { self.getFavoriteTeamId() },
            set: { newValue in self.setFavoriteTeamId(newValue) }
        )
    }

    // MARK: - Migration

    public func migratePreferredTeamIfNeeded() {
        let oldKey = "preferredTeam"
        let defaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier)

        if let oldTeamId = defaults?.string(forKey: oldKey), !oldTeamId.isEmpty {
            if _interestedTeamIds.isEmpty {
                _interestedTeamIds = [oldTeamId]
            }
            defaults?.removeObject(forKey: oldKey)
        }
    }

    // MARK: - Onboarding

    @CloudStorage(key: "hasCompletedOnboarding", default: false)
    public var hasCompletedOnboarding: Bool {
        didSet { objectWillChange.send() }
    }

    public func completeOnboarding() {
        objectWillChange.send()
        hasCompletedOnboarding = true
    }

    // MARK: - Security Settings

    @CloudStorage(key: "keychainSyncEnabled", default: true)
    public var keychainSyncEnabled: Bool {
        didSet { objectWillChange.send() }
    }

    // MARK: - User Management Settings

    @CloudStorage(key: "userManagementEnabled", default: false)
    public var userManagementEnabled: Bool {
        didSet {
            objectWillChange.send()
            if userManagementEnabled && !oldValue {
                Task { await handleUserManagementOptIn() }
            }
            if !userManagementEnabled && oldValue {
                Task { await handleUserManagementOptOut() }
            }
        }
    }

    @CloudStorage(key: "notificationSettings", default: NotificationSettings.default)
    public var notificationSettings: NotificationSettings {
        didSet {
            objectWillChange.send()
            if userManagementEnabled, let api = apiClient {
                Task {
                    try? await api.updateNotificationSettings(notificationSettings)
                }
            }
        }
    }

    // MARK: - User Management Actions

    private func handleUserManagementOptIn() async {
        do {
            let userId = try await AuthenticationManager.shared.register()
            print("User registered successfully: \(userId)")

            let teamIds = getInterestedTeamIds()
            if !teamIds.isEmpty, let api = apiClient {
                try? await api.setInterestedTeams(teamIds: teamIds)
            }

            if let api = apiClient {
                try? await api.updateNotificationSettings(notificationSettings)
            }

            try? await AuthenticationManager.shared.fetchUserProfile()
        } catch {
            print("Failed to opt-in to user management: \(error)")
            await MainActor.run {
                self.userManagementEnabled = false
            }
        }
    }

    private func handleUserManagementOptOut() async {
        do {
            try await AuthenticationManager.shared.logout()
        } catch {
            print("Failed to opt-out of user management: \(error)")
        }
    }

    // MARK: - Notification Reminder Tracking

    @CloudStorage(key: "matchViewInteractionCount", default: 0)
    public var matchViewInteractionCount: Int {
        didSet { objectWillChange.send() }
    }

    @CloudStorage(key: "hasSeenNotificationReminder", default: false)
    public var hasSeenNotificationReminder: Bool {
        didSet { objectWillChange.send() }
    }

    public func incrementMatchViewCount() {
        matchViewInteractionCount += 1
    }

    public func shouldShowNotificationReminder() -> Bool {
        return matchViewInteractionCount >= 10 && !hasSeenNotificationReminder
    }

    public func markNotificationReminderSeen() {
        hasSeenNotificationReminder = true
    }

    // MARK: - Binding Helpers

    public func binding_userManagementEnabled() -> Binding<Bool> {
        return Binding(
            get: { self.userManagementEnabled },
            set: { newValue in self.userManagementEnabled = newValue }
        )
    }

    public func binding_notificationSettings() -> Binding<NotificationSettings> {
        return Binding(
            get: { self.notificationSettings },
            set: { newValue in self.notificationSettings = newValue }
        )
    }

    public func binding_keychainSyncEnabled() -> Binding<Bool> {
        return Binding(
            get: { self.keychainSyncEnabled },
            set: { newValue in self.keychainSyncEnabled = newValue }
        )
    }
}
