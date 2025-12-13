//
//  WidgetStandings.swift
//  SHLWidget
//
//  Standings data model for widget display
//

import Foundation

struct WidgetStanding: Codable, Identifiable {
    let id: String
    let rank: Int
    let team: WidgetTeam
    let points: Int
    let gamesPlayed: Int
    let goalDifference: Int
    let wins: Int?
    let losses: Int?
    let overtimeLosses: Int?

    var isPlayoffPosition: Bool {
        rank <= 6
    }
}
