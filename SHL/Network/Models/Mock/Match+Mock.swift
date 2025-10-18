//
//  Match+Mock.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

extension Match {
    static func fakeData() -> Match {
        Match(
            id: "qeX-4AC927yoX",
            date: Date.distantPast,
            venue: "Be-Ge Hockey Center",
            homeTeam: TeamBasic(
                id: "team-1",
                name: "IK Oskarshamn",
                code: "IKO"
            ),
            awayTeam: TeamBasic(
                id: "team-2",
                name: "Frölunda HC",
                code: "FHC"
            ),
            homeScore: 3,
            awayScore: 2,
            gameState: .played,
            overtime: true,
            shootout: false
        )
    }

    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

extension Team {
    static func fakeData() -> Team {
        Team(
            id: "team-1",
            name: "IK Oskarshamn",
            code: "IKO",
            city: "Oskarshamn",
            founded: 1970,
            isActive: true
        )
    }
}
