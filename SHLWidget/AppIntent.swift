//
//  AppIntent.swift
//  SHLWidget
//
//  Created by user242911 on 1/4/24.
//  Updated with team configuration options
//

import WidgetKit
import AppIntents

// MARK: - Team Filter Option

enum TeamFilterOption: String, AppEnum {
    case featured = "featured"
    case lhf = "LHF"
    case fhc = "FHC"
    case ske = "SKE"
    case fbk = "FBK"
    case rbk = "RBK"
    case vlh = "VLH"
    case iko = "IKO"
    case hv71 = "HV71"
    case mif = "MIF"
    case lif = "LIF"
    case bif = "BIF"
    case tik = "TIK"
    case lhc = "LHC"
    case modo = "MODO"
    case ohk = "OHK"
    case dif = "DIF"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Team"

    static var caseDisplayRepresentations: [TeamFilterOption: DisplayRepresentation] = [
        .featured: DisplayRepresentation(title: "Featured Match", subtitle: "Show the next featured game"),
        .lhf: DisplayRepresentation(title: "Lulea Hockey", subtitle: "LHF"),
        .fhc: DisplayRepresentation(title: "Frolunda HC", subtitle: "FHC"),
        .ske: DisplayRepresentation(title: "Skelleftea AIK", subtitle: "SKE"),
        .fbk: DisplayRepresentation(title: "Farjestad BK", subtitle: "FBK"),
        .rbk: DisplayRepresentation(title: "Rogle BK", subtitle: "RBK"),
        .vlh: DisplayRepresentation(title: "Vaxjo Lakers", subtitle: "VLH"),
        .iko: DisplayRepresentation(title: "IK Oskarshamn", subtitle: "IKO"),
        .hv71: DisplayRepresentation(title: "HV71", subtitle: "HV71"),
        .mif: DisplayRepresentation(title: "Malmo Redhawks", subtitle: "MIF"),
        .lif: DisplayRepresentation(title: "Leksands IF", subtitle: "LIF"),
        .bif: DisplayRepresentation(title: "Brynas IF", subtitle: "BIF"),
        .tik: DisplayRepresentation(title: "Timra IK", subtitle: "TIK"),
        .lhc: DisplayRepresentation(title: "Linkoping HC", subtitle: "LHC"),
        .modo: DisplayRepresentation(title: "MODO Hockey", subtitle: "MODO"),
        .ohk: DisplayRepresentation(title: "Orebro HK", subtitle: "OHK"),
        .dif: DisplayRepresentation(title: "Djurgardens IF", subtitle: "DIF")
    ]

    var teamCode: String? {
        switch self {
        case .featured: return nil
        default: return self.rawValue
        }
    }
}

// MARK: - Upcoming Match Widget Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Upcoming Match"
    static var description = IntentDescription("Configure which team's matches to show")

    @Parameter(title: "Team", default: .featured)
    var teamFilter: TeamFilterOption
}

// MARK: - Standings Widget Intent

struct StandingsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "SHL Standings"
    static var description = IntentDescription("Configure standings widget options")

    @Parameter(title: "Highlight Team", default: .featured)
    var highlightTeam: TeamFilterOption
}

// MARK: - Team Schedule Widget Intent

struct TeamScheduleConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Team Schedule"
    static var description = IntentDescription("Show upcoming matches for a specific team")

    @Parameter(title: "Team", default: .lhf)
    var team: TeamFilterOption
}
