//
//  WidgetGame.swift
//  SHLWidget
//
//  Simple game model for widget use only
//

import Foundation

struct WidgetGame: Codable {
    let id: String
    let date: Date
    let venue: String
    let homeTeam: WidgetTeam
    let awayTeam: WidgetTeam
    let homeScore: Int
    let awayScore: Int

    func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    static func fakeData() -> WidgetGame {
        WidgetGame(
            id: "fake-1",
            date: Date(),
            venue: "Be-Ge Hockey Center",
            homeTeam: WidgetTeam(name: "IK Oskarshamn", code: "IKO"),
            awayTeam: WidgetTeam(name: "Frölunda HC", code: "FHC"),
            homeScore: 3,
            awayScore: 2
        )
    }
}

struct WidgetTeam: Codable {
    let name: String
    let code: String
}
