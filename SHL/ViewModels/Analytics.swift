//
//  Analytics.swift
//  SHL
//
//  Centralized, type-safe analytics facade over PostHog. Every product event flows
//  through `Analytics.track(_:)` and every screen through `Analytics.screen(_:)`,
//  so call sites stay terse and event names can never be mistyped. The whole layer
//  is a no-op until `start()` succeeds (and in DEBUG builds), meaning call sites
//  never need their own `#if !DEBUG` guards.
//

import Foundation
import PostHog
import SwiftUI

enum Analytics {
    private(set) static var isEnabled = false

    /// Configure PostHog. Call once at launch. No-op in DEBUG so local development
    /// never pollutes production analytics.
    static func start() {
        #if DEBUG
        return
        #else
        let config = PostHogConfig(
            apiKey: SharedPreferenceKeys.POSTHOG_API_KEY,
            host: SharedPreferenceKeys.POSTHOG_HOST
        )
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false // SwiftUI — we send screens via `screen(_:)`.
        PostHogSDK.shared.setup(config)
        isEnabled = true
        #endif
    }

    // MARK: - Events

    static func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        let props = event.properties
        PostHogSDK.shared.capture(event.name, properties: props.isEmpty ? nil : props)
    }

    static func screen(_ name: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        PostHogSDK.shared.screen(name, properties: properties.isEmpty ? nil : properties)
    }

    // MARK: - Identity

    /// Tie events to a stable (device-scoped) user id and set the properties we
    /// segment cohorts on.
    static func identify(userId: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        PostHogSDK.shared.identify(userId, userProperties: properties.isEmpty ? nil : properties)
    }

    /// Register super properties attached to every subsequent event (e.g. favorite
    /// team, follow count). Cheap to call repeatedly when the context changes.
    static func registerSuperProperties(_ properties: [String: Any]) {
        guard isEnabled else { return }
        PostHogSDK.shared.register(properties)
    }

    static func reset() {
        guard isEnabled else { return }
        PostHogSDK.shared.reset()
    }

    // MARK: - User context

    /// Refresh the super properties derived from the user's current preferences.
    /// Called at launch and whenever the followed teams / favorite change, so every
    /// event can be sliced by "has a favorite", follow count, etc.
    @MainActor
    static func refreshUserContext() {
        guard isEnabled else { return }
        let settings = Settings.shared
        registerSuperProperties([
            "interested_teams_count": settings.getInterestedTeamIds().count,
            "has_favorite_team": settings.getFavoriteTeamId() != nil,
            "favorite_team": settings.getFavoriteTeam()?.code ?? "none"
        ])
    }
}

extension View {
    /// Fire a screen view when this view appears. Use on tab destinations and
    /// high-intent sheets/details.
    func trackScreen(_ name: String, properties: [String: Any] = [:]) -> some View {
        onAppear { Analytics.screen(name, properties: properties) }
    }
}
