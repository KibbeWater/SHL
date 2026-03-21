//
//  PBPEventDTO.swift
//  SHL
//
//  Main DTO structure for Play-by-Play events
//

import Foundation

// MARK: - Main PBP Event DTO

/// Play-by-play event with generic fields and dynamic event-specific data
public struct PBPEventDTO: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let matchID: String
    public let eventType: String
    public let period: Int
    public let gameTime: String
    public let realWorldTime: Date
    public let teamID: String?
    public let playerID: String?
    public let description: String?

    /// Dynamic field containing event-specific data
    /// Type varies based on eventType
    public let data: EventData?

    /// Typed event type enum for easier switching
    public var typedEventType: PBPEventTypeEnum {
        PBPEventTypeEnum(rawValue: eventType.lowercased()) ?? .unknown
    }

    public init(id: String, matchID: String, eventType: String, period: Int, gameTime: String, realWorldTime: Date, teamID: String?, playerID: String?, description: String?, data: EventData?) {
        self.id = id
        self.matchID = matchID
        self.eventType = eventType
        self.period = period
        self.gameTime = gameTime
        self.realWorldTime = realWorldTime
        self.teamID = teamID
        self.playerID = playerID
        self.description = description
        self.data = data
    }
}

// MARK: - Event Data Enum

/// Wrapper enum for event-specific data structures
public enum EventData: Codable, Sendable, Equatable {
    case goal(GoalEventData)
    case shot(ShotEventData)
    case penalty(PenaltyEventData)
    case goalkeeper(GoalkeeperEventData)
    case timeout(TimeoutEventData)
    case shootout(ShootoutEventData)
    case period(PeriodEventData)
    case periodChange(PeriodChangeData)

    // MARK: - Coding

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
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

    public func encode(to encoder: Encoder) throws {
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

    public var asGoal: GoalEventData? {
        if case .goal(let data) = self { return data }
        return nil
    }

    public var asShot: ShotEventData? {
        if case .shot(let data) = self { return data }
        return nil
    }

    public var asPenalty: PenaltyEventData? {
        if case .penalty(let data) = self { return data }
        return nil
    }

    public var asGoalkeeper: GoalkeeperEventData? {
        if case .goalkeeper(let data) = self { return data }
        return nil
    }

    public var asTimeout: TimeoutEventData? {
        if case .timeout(let data) = self { return data }
        return nil
    }

    public var asShootout: ShootoutEventData? {
        if case .shootout(let data) = self { return data }
        return nil
    }

    public var asPeriod: PeriodEventData? {
        if case .period(let data) = self { return data }
        return nil
    }

    public var asPeriodChange: PeriodChangeData? {
        if case .periodChange(let data) = self { return data }
        return nil
    }
}

// MARK: - Event Type Enum

/// Typed event type for easier pattern matching
public enum PBPEventTypeEnum: String, Codable, Sendable {
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
