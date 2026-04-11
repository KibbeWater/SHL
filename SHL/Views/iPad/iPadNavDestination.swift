//
//  iPadNavDestination.swift
//  SHL
//
//  Navigation model for iPad sidebar and detail routing
//

import Foundation

enum iPadSidebarItem: Hashable {
    case home
    case schedule
    case standings
    case settings
    case team(Team)
}

enum iPadDetailRoute: Hashable {
    case match(Match)
    case team(Team)
    case player(Player)
}
