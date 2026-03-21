//
//  Match+Mock.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

extension Match {
    public static func fakeData() -> Match {
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
            state: .played,
            overtime: true,
            shootout: false, externalUUID: ""
        )
    }
}

extension Team {
    public static func fakeData() -> Team {
        Team(
            id: "team-1",
            name: "IK Oskarshamn",
            code: "IKO",
            city: "Oskarshamn",
            founded: 1970,
            venue: "Coop Norrbottens Arena",
            golds: 2,
            goldYears: [2024],
            finals: 2,
            finalYears: [2020, 2024],
            iconURL: nil,
            isActive: true
        )
    }
}
