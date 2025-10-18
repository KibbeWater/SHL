//
//  PBPEvents.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct PBPEvents: Codable {
    let matchId: String
    let events: [PBPEvent]
}

struct PBPEvent: Codable, Identifiable {
    let id: String
    let period: Int
    let time: String // MM:SS format
    let teamCode: String?
    let eventType: EventType
    let description: String
    let players: [EventPlayer]?
    let extra: EventExtra?
}

enum EventType: String, Codable {
    case goal = "goal"
    case penalty = "penalty"
    case shot = "shot"
    case save = "save"
    case faceoff = "faceoff"
    case hit = "hit"
    case block = "block"
    case periodStart = "period_start"
    case periodEnd = "period_end"
    case gameEnd = "game_end"
    case other = "other"
}

struct EventPlayer: Codable {
    let id: String
    let name: String
    let jerseyNumber: Int
    let role: String? // "scorer", "assist1", "assist2", etc
}

struct EventExtra: Codable {
    let shotType: String?
    let penaltyMinutes: Int?
    let penaltyType: String?
    let strength: String? // "even", "pp", "sh"
}
