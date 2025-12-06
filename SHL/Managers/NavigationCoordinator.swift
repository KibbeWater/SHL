//
//  NavigationCoordinator.swift
//  SHL
//
//  Created by Claude Code
//

import SwiftUI

/// Singleton coordinator to bridge notification/URL handling with SwiftUI navigation.
/// Used to trigger navigation from AppDelegate to Root view when tapping
/// Live Activities or notifications.
@MainActor
final class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    @Published var pendingMatchId: String?
    @Published var navigationSource: String?

    private init() {}

    /// Request navigation to a specific match
    /// - Parameters:
    ///   - id: The match's internal database ID
    ///   - source: Analytics source identifier (e.g., "live_activity", "push_goal")
    func navigateToMatch(id: String, source: String) {
        pendingMatchId = id
        navigationSource = source
    }

    /// Clear pending navigation after it has been handled
    func clearPending() {
        pendingMatchId = nil
        navigationSource = nil
    }
}
