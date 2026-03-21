//
//  Root.swift
//  SHL
//
//  Shared tab enum used by Root_iOS and Root_iPadOS
//

import SHLNetwork

enum RootTabs: Equatable, Hashable, Identifiable {
    case home
    case calendar
    case settings
    case search
    case team(Team)

    var id: String {
        switch self {
        case .home: return "home"
        case .calendar: return "calendar"
        case .settings: return "settings"
        case .search: return "search"
        case .team(let team): return "team_\(team.id)"
        }
    }
}
