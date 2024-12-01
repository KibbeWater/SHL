//
//  Game.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit

extension Game {
    static func fakeData() -> Game {
        Game(
            id: "qeX-4AC927yoX",
            date: Date.distantPast,
            played: true,
            overtime: true,
            shootout: false,
            venue: "Be-Ge Hockey Center",
            homeTeam: Team.fakeData(),
            awayTeam: Team.fakeData()
        )
    }
}
