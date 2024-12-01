//
//  SHLWidgetAttributes.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import ActivityKit

public struct SHLWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var homeScore: Int
        public var awayScore: Int
        public var period: ActivityPeriod
        
        public init(homeScore: Int, awayScore: Int, period: ActivityPeriod) {
            self.homeScore = homeScore
            self.awayScore = awayScore
            self.period = period
        }
        
        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<SHLWidgetAttributes.ContentState.CodingKeys> = try decoder.container(keyedBy: SHLWidgetAttributes.ContentState.CodingKeys.self)
            self.homeScore = try container.decode(Int.self, forKey: SHLWidgetAttributes.ContentState.CodingKeys.homeScore)
            self.awayScore = try container.decode(Int.self, forKey: SHLWidgetAttributes.ContentState.CodingKeys.awayScore)
            self.period = try container.decode(ActivityPeriod.self, forKey: SHLWidgetAttributes.ContentState.CodingKeys.period)
        }
    }
    
    public var id: String
    public var homeTeam: ActivityTeam
    public var awayTeam: ActivityTeam
    
    public init(id: String, homeTeam: ActivityTeam, awayTeam: ActivityTeam) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
    }
    
    public enum ActivityState: String, Codable {
        case starting = "NotStarted"
        case ongoing = "Ongoing"
        case onbreak = "PeriodBreak"
        case overtime = "Overtime"
        case ended = "GameEnded"
        case intermission = "Intermission"
    }

    public struct ActivityTeam: Codable {
        public var name: String
        public var teamCode: String
        
        public init(name: String, teamCode: String) {
            self.name = name
            self.teamCode = teamCode
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.teamCode = try container.decode(String.self, forKey: .teamCode)
        }
    }

    public struct ActivityPeriod: Codable, Hashable {
        public var period: Int
        public var periodEnd: String
        public var state: ActivityState
        
        public init(period: Int, periodEnd: String, state: ActivityState) {
            self.period = period
            self.periodEnd = periodEnd
            self.state = state
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.period = try container.decode(Int.self, forKey: .period)
            self.periodEnd = try container.decode(String.self, forKey: .periodEnd)
            self.state = try container.decode(ActivityState.self, forKey: .state)
        }
    }}
