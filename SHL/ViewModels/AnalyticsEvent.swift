//
//  AnalyticsEvent.swift
//  SHL
//
//  The single source of truth for product analytics. Each case maps to a
//  `snake_case` event name and a properties dictionary. Organized by the product
//  question each group answers — activation, home engagement, schedule engagement,
//  content depth, feature adoption, and feedback — so the taxonomy stays legible.
//
//  Privacy: only enums, booleans, counts and lengths are ever emitted — never the
//  content of a feedback message, and no personal identifiers.
//

import Foundation

enum AnalyticsEvent {
    // MARK: - Lifecycle
    case appOpened(source: String)

    // MARK: - Activation funnel (onboarding)
    case onboardingStarted
    case onboardingPageViewed(page: Int, name: String)
    case onboardingTeamSelection(skipped: Bool, count: Int)
    case onboardingFavoriteTeam(skipped: Bool, hasFavorite: Bool)
    case onboardingOnlineFeatures(enabled: Bool)
    case onboardingCompleted(durationSeconds: Double, teamsCount: Int, hasFavorite: Bool,
                             skippedTeams: Bool, skippedFavorite: Bool)

    // MARK: - Home engagement
    case homeViewed(phase: String, hasFavorite: Bool)
    case homeFavoriteTapped
    case homeSeasonCardTapped(phase: String)
    case homeFeaturedTapped(isLive: Bool)
    case homeLiveGameTapped
    case homeGamesTabChanged(tab: String) // "upcoming" | "results"
    case homeStandingsSeeAll
    case homeLeaderboardSeen(board: String)

    // MARK: - Schedule engagement
    case scheduleDateSelected(daysFromToday: Int)
    case scheduleWeekPaged(direction: String) // "forward" | "back"
    case scheduleJumpToDate
    case scheduleTeamFilterChanged(active: Bool)
    case scheduleMatchTapped(isLive: Bool)

    // MARK: - Content depth
    case matchOpened(referrer: String)
    case matchTabChanged(tab: String)
    case teamOpened(source: String)
    case playerOpened(source: String)

    // MARK: - Feature adoption (notifications / live activities)
    case notificationPermissionResult(granted: Bool)
    case teamNotificationLevelChanged(level: String)
    case liveActivityAutoStartToggled(enabled: Bool)
    case matchReminderCreated
    case liveActivityStarted(joinType: String)

    // MARK: - Feedback
    case feedbackOpened(source: String)
    case feedbackSubmitted(category: String, length: Int)

    /// `snake_case` event name sent to PostHog.
    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingPageViewed: return "onboarding_page_viewed"
        case .onboardingTeamSelection: return "onboarding_team_selection"
        case .onboardingFavoriteTeam: return "onboarding_favorite_team"
        case .onboardingOnlineFeatures: return "onboarding_online_features"
        case .onboardingCompleted: return "onboarding_completed"
        case .homeViewed: return "home_viewed"
        case .homeFavoriteTapped: return "home_favorite_tapped"
        case .homeSeasonCardTapped: return "home_season_card_tapped"
        case .homeFeaturedTapped: return "home_featured_tapped"
        case .homeLiveGameTapped: return "home_live_game_tapped"
        case .homeGamesTabChanged: return "home_games_tab_changed"
        case .homeStandingsSeeAll: return "home_standings_see_all"
        case .homeLeaderboardSeen: return "home_leaderboard_seen"
        case .scheduleDateSelected: return "schedule_date_selected"
        case .scheduleWeekPaged: return "schedule_week_paged"
        case .scheduleJumpToDate: return "schedule_jump_to_date"
        case .scheduleTeamFilterChanged: return "schedule_team_filter_changed"
        case .scheduleMatchTapped: return "schedule_match_tapped"
        case .matchOpened: return "match_opened"
        case .matchTabChanged: return "match_tab_changed"
        case .teamOpened: return "team_opened"
        case .playerOpened: return "player_opened"
        case .notificationPermissionResult: return "notification_permission_result"
        case .teamNotificationLevelChanged: return "team_notification_level_changed"
        case .liveActivityAutoStartToggled: return "live_activity_autostart_toggled"
        case .matchReminderCreated: return "match_reminder_created"
        case .liveActivityStarted: return "started_live_activity"
        case .feedbackOpened: return "feedback_opened"
        case .feedbackSubmitted: return "feedback_submitted"
        }
    }

    var properties: [String: Any] {
        switch self {
        case let .appOpened(source):
            return ["source": source]
        case let .onboardingPageViewed(page, name):
            return ["page_number": page, "page_name": name]
        case let .onboardingTeamSelection(skipped, count):
            return ["skipped": skipped, "teams_selected_count": count]
        case let .onboardingFavoriteTeam(skipped, hasFavorite):
            return ["skipped": skipped, "has_favorite": hasFavorite]
        case let .onboardingOnlineFeatures(enabled):
            return ["enabled": enabled, "action": enabled ? "enable_now" : "not_now"]
        case let .onboardingCompleted(duration, teamsCount, hasFavorite, skippedTeams, skippedFavorite):
            return ["duration_seconds": duration, "teams_selected_count": teamsCount,
                    "has_favorite_team": hasFavorite, "skipped_team_selection": skippedTeams,
                    "skipped_favorite_team": skippedFavorite]
        case let .homeViewed(phase, hasFavorite):
            return ["phase": phase, "has_favorite": hasFavorite]
        case let .homeSeasonCardTapped(phase):
            return ["phase": phase]
        case let .homeFeaturedTapped(isLive):
            return ["is_live": isLive]
        case let .homeGamesTabChanged(tab):
            return ["tab": tab]
        case let .homeLeaderboardSeen(board):
            return ["board": board]
        case let .scheduleDateSelected(days):
            return ["days_from_today": days]
        case let .scheduleWeekPaged(direction):
            return ["direction": direction]
        case let .scheduleTeamFilterChanged(active):
            return ["active": active]
        case let .scheduleMatchTapped(isLive):
            return ["is_live": isLive]
        case let .matchOpened(referrer):
            return ["referrer": referrer]
        case let .matchTabChanged(tab):
            return ["tab": tab]
        case let .teamOpened(source):
            return ["source": source]
        case let .playerOpened(source):
            return ["source": source]
        case let .notificationPermissionResult(granted):
            return ["granted": granted]
        case let .teamNotificationLevelChanged(level):
            return ["level": level]
        case let .liveActivityAutoStartToggled(enabled):
            return ["enabled": enabled]
        case let .liveActivityStarted(joinType):
            return ["join_type": joinType]
        case let .feedbackOpened(source):
            return ["source": source]
        case let .feedbackSubmitted(category, length):
            return ["category": category, "length": length]
        default:
            return [:]
        }
    }
}
