//
//  PBPEvents.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
import HockeyKit

// MARK: - Backend API Model (from SHLBackend)
struct PBPEvent: Codable, Identifiable {
    let id: String
    let matchID: String
    let eventType: String
    let period: Int
    let gameTime: String
    let realWorldTime: Date
    let teamID: String?
    let playerID: String?
    let description: String?
    let metadata: [String: String]?
}

// MARK: - HockeyKit Compatibility Adapters

/// Wrapper to match HockeyKit's PBPEvents structure
struct PBPEventsAdapter {
    let events: [PBPEventProtocol]

    /// Convert backend PBPEvent array to HockeyKit-compatible event array
    static func from(backendEvents: [PBPEvent], match: Match) -> PBPEventsAdapter {
        let adaptedEvents = backendEvents.compactMap { event -> PBPEventProtocol? in
            switch event.eventType.lowercased() {
            case "goal":
                return AdaptedGoalEvent(from: event, match: match)
            case "penalty":
                return AdaptedPenaltyEvent(from: event, match: match)
            case "shot":
                return AdaptedShotEvent(from: event, match: match)
            case "period_start", "period_end":
                return AdaptedPeriodEvent(from: event, match: match)
            case "goalkeeper_change":
                return AdaptedGoalkeeperEvent(from: event, match: match)
            case "timeout":
                return AdaptedTimeoutEvent(from: event, match: match)
            default:
                return nil
            }
        }
        return PBPEventsAdapter(events: adaptedEvents)
    }
}

// MARK: - Adapted Event Types (HockeyKit-compatible)

struct AdaptedGoalEvent: PBPEventProtocol {
    let gameId: Int = 0
    let gameSourceId: String
    let gameUuid: String
    let period: Int
    let realWorldTime: Date
    let type: PBPEventType = .goal

    let time: String
    let player: PBPlayer
    let homeGoals: Int
    let awayGoals: Int
    let homeTeam: PBPTeam
    let awayTeam: PBPTeam
    let eventTeam: PBPEventTeam
    let goalSection: Int = 0
    let isEmptyNetGoal: Bool = false
    let assists: AssistDictionary?
    let locationX: Int = 0
    let locationY: Int = 0

    struct AssistDictionary: Codable, Sendable {
        let first: PBPlayer?
        let second: PBPlayer?
    }

    init?(from event: PBPEvent, match: Match) {
        guard event.eventType.lowercased() == "goal" else { return nil }

        self.gameSourceId = event.matchID
        self.gameUuid = event.matchID
        self.period = event.period
        self.realWorldTime = event.realWorldTime
        self.time = event.gameTime

        // Extract player info from metadata
        let playerFirstName = event.metadata?["playerFirstName"] ?? ""
        let playerLastName = event.metadata?["playerLastName"] ?? ""
        let jerseyNumber = Int(event.metadata?["jerseyNumber"] ?? "0") ?? 0

        self.player = PBPlayer(
            id: event.playerID ?? "",
            firstName: playerFirstName,
            familyName: playerLastName,
            jerseyToday: jerseyNumber
        )

        // Extract scores
        self.homeGoals = Int(event.metadata?["homeScore"] ?? "0") ?? 0
        self.awayGoals = Int(event.metadata?["awayScore"] ?? "0") ?? 0

        // Create team data
        self.homeTeam = PBPTeam(
            teamId: match.homeTeam.id ?? "",
            teamName: match.homeTeam.name,
            teamCode: match.homeTeam.code
        )
        self.awayTeam = PBPTeam(
            teamId: match.awayTeam.id ?? "",
            teamName: match.awayTeam.name,
            teamCode: match.awayTeam.code
        )

        // Determine event team
        let isHomeTeam = event.teamID == match.homeTeam.id
        self.eventTeam = PBPEventTeam(
            teamId: event.teamID ?? "",
            teamName: isHomeTeam ? match.homeTeam.name : match.awayTeam.name,
            teamCode: isHomeTeam ? match.homeTeam.code : match.awayTeam.code,
            place: isHomeTeam ? .home : .away
        )

        // Extract assists if available
        if let assist1ID = event.metadata?["assistPlayer1"],
           let assist1First = event.metadata?["assistPlayer1FirstName"],
           let assist1Last = event.metadata?["assistPlayer1LastName"] {
            let assist1Jersey = Int(event.metadata?["assistPlayer1Jersey"] ?? "0") ?? 0
            let firstAssist = PBPlayer(id: assist1ID, firstName: assist1First, familyName: assist1Last, jerseyToday: assist1Jersey)

            var secondAssist: PBPlayer? = nil
            if let assist2ID = event.metadata?["assistPlayer2"],
               let assist2First = event.metadata?["assistPlayer2FirstName"],
               let assist2Last = event.metadata?["assistPlayer2LastName"] {
                let assist2Jersey = Int(event.metadata?["assistPlayer2Jersey"] ?? "0") ?? 0
                secondAssist = PBPlayer(id: assist2ID, firstName: assist2First, familyName: assist2Last, jerseyToday: assist2Jersey)
            }

            self.assists = AssistDictionary(first: firstAssist, second: secondAssist)
        } else {
            self.assists = nil
        }
    }
}

struct AdaptedPenaltyEvent: PBPEventProtocol {
    let gameId: Int = 0
    let gameSourceId: String
    let gameUuid: String
    let period: Int
    let realWorldTime: Date
    let type: PBPEventType = .penalty

    let time: String
    let player: PBPlayer?
    let offence: String
    let variant: PenaltyVariant
    let homeTeam: PBPTeam
    let awayTeam: PBPTeam
    let eventTeam: PBPEventTeam

    struct PenaltyVariant: Codable, Sendable {
        let description: String?
    }

    init?(from event: PBPEvent, match: Match) {
        guard event.eventType.lowercased() == "penalty" else { return nil }

        self.gameSourceId = event.matchID
        self.gameUuid = event.matchID
        self.period = event.period
        self.realWorldTime = event.realWorldTime
        self.time = event.gameTime

        // Extract player info if available
        if let playerID = event.playerID,
           let firstName = event.metadata?["playerFirstName"],
           let lastName = event.metadata?["playerLastName"] {
            let jersey = Int(event.metadata?["jerseyNumber"] ?? "0") ?? 0
            self.player = PBPlayer(id: playerID, firstName: firstName, familyName: lastName, jerseyToday: jersey)
        } else {
            self.player = nil
        }

        self.offence = event.metadata?["offence"] ?? event.description ?? "Penalty"
        self.variant = PenaltyVariant(description: event.metadata?["penaltyType"])

        // Create team data
        self.homeTeam = PBPTeam(
            teamId: match.homeTeam.id ?? "",
            teamName: match.homeTeam.name,
            teamCode: match.homeTeam.code
        )
        self.awayTeam = PBPTeam(
            teamId: match.awayTeam.id ?? "",
            teamName: match.awayTeam.name,
            teamCode: match.awayTeam.code
        )

        let isHomeTeam = event.teamID == match.homeTeam.id
        self.eventTeam = PBPEventTeam(
            teamId: event.teamID ?? "",
            teamName: isHomeTeam ? match.homeTeam.name : match.awayTeam.name,
            teamCode: isHomeTeam ? match.homeTeam.code : match.awayTeam.code,
            place: isHomeTeam ? .home : .away
        )
    }
}

struct AdaptedShotEvent: PBPEventProtocol {
    let gameId: Int = 0
    let gameSourceId: String
    let gameUuid: String
    let period: Int
    let realWorldTime: Date
    let type: PBPEventType = .shot

    let time: String
    let player: PBPlayer
    let homeTeam: PBPTeam
    let awayTeam: PBPTeam
    let eventTeam: PBPEventTeam

    init?(from event: PBPEvent, match: Match) {
        guard event.eventType.lowercased() == "shot" else { return nil }

        self.gameSourceId = event.matchID
        self.gameUuid = event.matchID
        self.period = event.period
        self.realWorldTime = event.realWorldTime
        self.time = event.gameTime

        let firstName = event.metadata?["playerFirstName"] ?? ""
        let lastName = event.metadata?["playerLastName"] ?? ""
        let jersey = Int(event.metadata?["jerseyNumber"] ?? "0") ?? 0

        self.player = PBPlayer(
            id: event.playerID ?? "",
            firstName: firstName,
            familyName: lastName,
            jerseyToday: jersey
        )

        // Create team data
        self.homeTeam = PBPTeam(
            teamId: match.homeTeam.id ?? "",
            teamName: match.homeTeam.name,
            teamCode: match.homeTeam.code
        )
        self.awayTeam = PBPTeam(
            teamId: match.awayTeam.id ?? "",
            teamName: match.awayTeam.name,
            teamCode: match.awayTeam.code
        )

        let isHomeTeam = event.teamID == match.homeTeam.id
        self.eventTeam = PBPEventTeam(
            teamId: event.teamID ?? "",
            teamName: isHomeTeam ? match.homeTeam.name : match.awayTeam.name,
            teamCode: isHomeTeam ? match.homeTeam.code : match.awayTeam.code,
            place: isHomeTeam ? .home : .away
        )
    }
}

struct AdaptedPeriodEvent: PBPEventProtocol {
    let gameId: Int = 0
    let gameSourceId: String
    let gameUuid: String
    let period: Int
    let realWorldTime: Date
    let type: PBPEventType = .period

    let started: Bool
    let finished: Bool

    init?(from event: PBPEvent, match: Match) {
        let eventTypeLower = event.eventType.lowercased()
        guard eventTypeLower == "period_start" || eventTypeLower == "period_end" else { return nil }

        self.gameSourceId = event.matchID
        self.gameUuid = event.matchID
        self.period = event.period
        self.realWorldTime = event.realWorldTime

        self.started = eventTypeLower == "period_start"
        self.finished = eventTypeLower == "period_end"
    }
}

struct AdaptedGoalkeeperEvent: PBPEventProtocol {
    let gameId: Int = 0
    let gameSourceId: String
    let gameUuid: String
    let period: Int
    let realWorldTime: Date
    let type: PBPEventType = .goalkeeper

    let time: String
    let player: PBPlayer
    let isEntering: Bool
    let homeTeam: PBPTeam
    let awayTeam: PBPTeam
    let eventTeam: PBPEventTeam

    init?(from event: PBPEvent, match: Match) {
        guard event.eventType.lowercased() == "goalkeeper_change" else { return nil }

        self.gameSourceId = event.matchID
        self.gameUuid = event.matchID
        self.period = event.period
        self.realWorldTime = event.realWorldTime
        self.time = event.gameTime

        let firstName = event.metadata?["playerFirstName"] ?? ""
        let lastName = event.metadata?["playerLastName"] ?? ""
        let jersey = Int(event.metadata?["jerseyNumber"] ?? "0") ?? 0

        self.player = PBPlayer(
            id: event.playerID ?? "",
            firstName: firstName,
            familyName: lastName,
            jerseyToday: jersey
        )

        self.isEntering = event.metadata?["action"] == "entering"

        // Create team data
        self.homeTeam = PBPTeam(
            teamId: match.homeTeam.id ?? "",
            teamName: match.homeTeam.name,
            teamCode: match.homeTeam.code
        )
        self.awayTeam = PBPTeam(
            teamId: match.awayTeam.id ?? "",
            teamName: match.awayTeam.name,
            teamCode: match.awayTeam.code
        )

        let isHomeTeam = event.teamID == match.homeTeam.id
        self.eventTeam = PBPEventTeam(
            teamId: event.teamID ?? "",
            teamName: isHomeTeam ? match.homeTeam.name : match.awayTeam.name,
            teamCode: isHomeTeam ? match.homeTeam.code : match.awayTeam.code,
            place: isHomeTeam ? .home : .away
        )
    }
}

struct AdaptedTimeoutEvent: PBPEventProtocol {
    let gameId: Int = 0
    let gameSourceId: String
    let gameUuid: String
    let period: Int
    let realWorldTime: Date
    let type: PBPEventType = .timeout

    let time: String
    let homeTeam: PBPTeam
    let awayTeam: PBPTeam
    let eventTeam: PBPEventTeam

    init?(from event: PBPEvent, match: Match) {
        guard event.eventType.lowercased() == "timeout" else { return nil }

        self.gameSourceId = event.matchID
        self.gameUuid = event.matchID
        self.period = event.period
        self.realWorldTime = event.realWorldTime
        self.time = event.gameTime

        // Create team data
        self.homeTeam = PBPTeam(
            teamId: match.homeTeam.id ?? "",
            teamName: match.homeTeam.name,
            teamCode: match.homeTeam.code
        )
        self.awayTeam = PBPTeam(
            teamId: match.awayTeam.id ?? "",
            teamName: match.awayTeam.name,
            teamCode: match.awayTeam.code
        )

        let isHomeTeam = event.teamID == match.homeTeam.id
        self.eventTeam = PBPEventTeam(
            teamId: event.teamID ?? "",
            teamName: isHomeTeam ? match.homeTeam.name : match.awayTeam.name,
            teamCode: isHomeTeam ? match.homeTeam.code : match.awayTeam.code,
            place: isHomeTeam ? .home : .away
        )
    }
}

// MARK: - Helper Types

struct PBPTeam: Codable, Equatable, Sendable {
    let teamId: String
    let teamName: String
    let teamCode: String
}

struct PBPEventTeam: Codable, Equatable, Sendable {
    let teamId: String
    let teamName: String
    let teamCode: String
    let place: PlaceType

    enum PlaceType: String, Codable, Sendable {
        case home
        case away
    }
}

struct PBPlayer: Codable, Equatable, Sendable {
    let id: String
    let firstName: String
    let familyName: String
    let jerseyToday: Int
}
