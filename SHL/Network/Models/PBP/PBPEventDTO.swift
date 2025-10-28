//
//  PBPEventDTO.swift
//  SHL
//
//  Main DTO structure for Play-by-Play events
//

import Foundation

// MARK: - Main PBP Event DTO

/// Play-by-play event with generic fields and dynamic event-specific data
struct PBPEventDTO: Codable, Identifiable, Sendable {
    let id: String
    let matchID: String
    let eventType: String
    let period: Int
    let gameTime: String
    let realWorldTime: Date
    let teamID: String?
    let playerID: String?
    let description: String?

    /// Dynamic field containing event-specific data
    /// Type varies based on eventType
    let data: EventData?

    /// Typed event type enum for easier switching
    var typedEventType: PBPEventTypeEnum {
        PBPEventTypeEnum(rawValue: eventType.lowercased()) ?? .unknown
    }
}

// MARK: - Event Data Enum

/// Wrapper enum for event-specific data structures
enum EventData: Codable, Sendable {
    case goal(GoalEventData)
    case shot(ShotEventData)
    case penalty(PenaltyEventData)
    case goalkeeper(GoalkeeperEventData)
    case timeout(TimeoutEventData)
    case shootout(ShootoutEventData)
    case period(PeriodEventData)
    case periodChange(PeriodChangeData)

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as each type
        if let goalData = try? container.decode(GoalEventData.self) {
            self = .goal(goalData)
        } else if let shotData = try? container.decode(ShotEventData.self) {
            self = .shot(shotData)
        } else if let penaltyData = try? container.decode(PenaltyEventData.self) {
            self = .penalty(penaltyData)
        } else if let goalkeeperData = try? container.decode(GoalkeeperEventData.self) {
            self = .goalkeeper(goalkeeperData)
        } else if let timeoutData = try? container.decode(TimeoutEventData.self) {
            self = .timeout(timeoutData)
        } else if let shootoutData = try? container.decode(ShootoutEventData.self) {
            self = .shootout(shootoutData)
        } else if let periodData = try? container.decode(PeriodEventData.self) {
            self = .period(periodData)
        } else if let periodChangeData = try? container.decode(PeriodChangeData.self) {
            self = .periodChange(periodChangeData)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode EventData - unknown type"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .goal(let data):
            try container.encode(data)
        case .shot(let data):
            try container.encode(data)
        case .penalty(let data):
            try container.encode(data)
        case .goalkeeper(let data):
            try container.encode(data)
        case .timeout(let data):
            try container.encode(data)
        case .shootout(let data):
            try container.encode(data)
        case .period(let data):
            try container.encode(data)
        case .periodChange(let data):
            try container.encode(data)
        }
    }

    // MARK: - Convenience Accessors

    var asGoal: GoalEventData? {
        if case .goal(let data) = self { return data }
        return nil
    }

    var asShot: ShotEventData? {
        if case .shot(let data) = self { return data }
        return nil
    }

    var asPenalty: PenaltyEventData? {
        if case .penalty(let data) = self { return data }
        return nil
    }

    var asGoalkeeper: GoalkeeperEventData? {
        if case .goalkeeper(let data) = self { return data }
        return nil
    }

    var asTimeout: TimeoutEventData? {
        if case .timeout(let data) = self { return data }
        return nil
    }

    var asShootout: ShootoutEventData? {
        if case .shootout(let data) = self { return data }
        return nil
    }

    var asPeriod: PeriodEventData? {
        if case .period(let data) = self { return data }
        return nil
    }

    var asPeriodChange: PeriodChangeData? {
        if case .periodChange(let data) = self { return data }
        return nil
    }
}

// MARK: - Event Type Enum

/// Typed event type for easier pattern matching
enum PBPEventTypeEnum: String, Codable, Sendable {
    case goal
    case shot
    case penalty
    case goalkeeper
    case timeout
    case shootout = "shootout-penalty-shot"
    case period
    case periodChange = "period-change"
    case unknown
}
