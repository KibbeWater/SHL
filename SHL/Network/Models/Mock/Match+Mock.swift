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
            state: .played,
            overtime: true,
            shootout: false, externalUUID: ""
        )
    }

    static func cancelledFakeData() -> Match {
        Match(
            id: "cancelled-mock",
            date: Date().addingTimeInterval(-3600),
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
            homeScore: 0,
            awayScore: 0,
            state: .cancelled,
            overtime: false,
            shootout: false,
            externalUUID: "cancelled-mock-ext"
        )
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
