//
//  SHLWidgetTeamSchedule.swift
//  SHLWidget
//
//  Shows upcoming matches for a specific team
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct TeamScheduleEntry: TimelineEntry {
    let date: Date
    let teamCode: String
    let teamName: String
    let matches: [WidgetGame]
    let loadError: Bool

    static func placeholder(teamCode: String = "LHF", teamName: String = "Lulea Hockey") -> TeamScheduleEntry {
        TeamScheduleEntry(
            date: Date(),
            teamCode: teamCode,
            teamName: teamName,
            matches: Self.fakeMatches(for: teamCode),
            loadError: false
        )
    }

    static func error(teamCode: String, teamName: String) -> TeamScheduleEntry {
        TeamScheduleEntry(
            date: Date(),
            teamCode: teamCode,
            teamName: teamName,
            matches: [],
            loadError: true
        )
    }

    static func fakeMatches(for teamCode: String) -> [WidgetGame] {
        let opponents = ["FHC", "SKE", "RBK", "VLH", "MODO"]
        return opponents.enumerated().map { index, opponent in
            WidgetGame(
                id: "\(index)",
                date: Calendar.current.date(byAdding: .day, value: index * 3 + 1, to: Date()) ?? Date(),
                venue: index % 2 == 0 ? "Home Arena" : "Away Arena",
                homeTeam: index % 2 == 0
                    ? WidgetTeam(name: "Lulea Hockey", code: teamCode)
                    : WidgetTeam(name: "Opponent", code: opponent),
                awayTeam: index % 2 == 0
                    ? WidgetTeam(name: "Opponent", code: opponent)
                    : WidgetTeam(name: "Lulea Hockey", code: teamCode),
                homeScore: 0,
                awayScore: 0
            )
        }
    }
}

// MARK: - Timeline Provider

struct TeamScheduleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TeamScheduleEntry {
        TeamScheduleEntry.placeholder()
    }

    func snapshot(for configuration: TeamScheduleConfigurationIntent, in context: Context) async -> TeamScheduleEntry {
        let teamCode = configuration.team.teamCode ?? "LHF"
        let teamName = TeamScheduleProvider.teamName(for: teamCode)
        return TeamScheduleEntry.placeholder(teamCode: teamCode, teamName: teamName)
    }

    func timeline(for configuration: TeamScheduleConfigurationIntent, in context: Context) async -> Timeline<TeamScheduleEntry> {
        let teamCode = configuration.team.teamCode ?? "LHF"
        let teamName = TeamScheduleProvider.teamName(for: teamCode)
        let api = WidgetAPI()

        // Get cached data (triggers background refresh if stale)
        let matches = api.getTeamMatches(teamCode: teamCode) ?? []

        // Filter to only upcoming matches
        let upcomingMatches = matches.filter { $0.date > Date() }

        if matches.isEmpty {
            // No cached data - show error and retry soon
            let entry = TeamScheduleEntry.error(teamCode: teamCode, teamName: teamName)
            let retryDate = Date.now.addingTimeInterval(60) // Retry in 1 minute
            return Timeline(entries: [entry], policy: .after(retryDate))
        }

        let entry = TeamScheduleEntry(
            date: Date.now,
            teamCode: teamCode,
            teamName: teamName,
            matches: upcomingMatches,
            loadError: false
        )

        // Smart update interval
        let nextUpdate = calculateNextUpdate(for: upcomingMatches.first)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func calculateNextUpdate(for nextMatch: WidgetGame?) -> Date {
        guard let match = nextMatch else {
            return Date.now.addingTimeInterval(60 * 60) // 1 hour if no matches
        }

        let timeUntilGame = match.date.timeIntervalSince(Date.now)

        if timeUntilGame < 60 * 60 {
            return Date.now.addingTimeInterval(10 * 60) // 10 min if within 1 hour
        } else if timeUntilGame < 24 * 60 * 60 {
            return Date.now.addingTimeInterval(30 * 60) // 30 min if today
        } else {
            return Date.now.addingTimeInterval(60 * 60) // 1 hour otherwise
        }
    }

    static func teamName(for code: String) -> String {
        let names: [String: String] = [
            "LHF": "Lulea Hockey",
            "FHC": "Frolunda HC",
            "SKE": "Skelleftea AIK",
            "FBK": "Farjestad BK",
            "RBK": "Rogle BK",
            "VLH": "Vaxjo Lakers",
            "IKO": "IK Oskarshamn",
            "HV71": "HV71",
            "MIF": "Malmo Redhawks",
            "LIF": "Leksands IF",
            "BIF": "Brynas IF",
            "TIK": "Timra IK",
            "LHC": "Linkoping HC",
            "MODO": "MODO Hockey",
            "OHK": "Orebro HK",
            "DIF": "Djurgardens IF"
        ]
        return names[code] ?? code
    }
}

// MARK: - Widget Views

struct TeamScheduleEntryView: View {
    var entry: TeamScheduleEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.loadError {
            TeamScheduleErrorView(teamCode: entry.teamCode)
        } else {
            switch family {
            case .systemSmall:
                SmallScheduleView(entry: entry)
            case .systemMedium:
                MediumScheduleView(entry: entry)
            default:
                MediumScheduleView(entry: entry)
            }
        }
    }
}

// MARK: - Error View

private struct TeamScheduleErrorView: View {
    let teamCode: String

    private var teamColor: Color {
        TeamColorCache.color(for: teamCode)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image("Team/\(teamCode)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            Text("Unable to load schedule")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            ZStack {
                Color(white: 0.12)
                LinearGradient(
                    colors: [teamColor.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Small Schedule View

private struct SmallScheduleView: View {
    let entry: TeamScheduleEntry

    private var nextMatch: WidgetGame? {
        entry.matches.first
    }

    private var teamColor: Color {
        TeamColorCache.color(for: entry.teamCode)
    }

    private var isToday: Bool {
        guard let match = nextMatch else { return false }
        return Calendar.current.isDate(match.date, inSameDayAs: Date())
    }

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Text("SCHEDULE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1.2)

                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 3, height: 3)

                Text(entry.teamCode)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            if let match = nextMatch {
                let opponent = match.homeTeam.code == entry.teamCode ? match.awayTeam : match.homeTeam
                let isHome = match.homeTeam.code == entry.teamCode

                // Team logos matchup
                HStack {
                    Spacer()

                    // Our team
                    VStack(spacing: 4) {
                        Image("Team/\(entry.teamCode)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 42, height: 42)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                        Text(entry.teamCode)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    // vs/@ indicator
                    Text(isHome ? "vs" : "@")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    // Opponent
                    VStack(spacing: 4) {
                        Image("Team/\(opponent.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 42, height: 42)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                        Text(opponent.code)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }

                // Date and time
                VStack(spacing: 6) {
                    // Time pill
                    Text(match.formatTime())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                        )

                    // Date
                    if isToday {
                        Text("TODAY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.yellow)
                    } else {
                        Text(match.formatDate().uppercased())
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()
            } else {
                Spacer()
                Image("Team/\(entry.teamCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .opacity(0.5)
                Text("No upcoming matches")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .containerBackground(for: .widget) {
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [teamColor, teamColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Overlay for depth
                LinearGradient(
                    colors: [.black.opacity(0.1), .clear, .black.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Medium Schedule View

private struct MediumScheduleView: View {
    let entry: TeamScheduleEntry

    private var upcomingMatches: [WidgetGame] {
        Array(entry.matches.prefix(3))
    }

    private var teamColor: Color {
        TeamColorCache.color(for: entry.teamCode)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header bar
            HStack(spacing: 6) {
                Image("Team/\(entry.teamCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)

                Text("SCHEDULE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.5)

                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 3, height: 3)

                Text(entry.teamCode)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("\(upcomingMatches.count) UPCOMING")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            if upcomingMatches.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No upcoming matches")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            } else {
                VStack(spacing: 4) {
                    ForEach(upcomingMatches, id: \.id) { match in
                        ScheduleMatchRow(match: match, teamCode: entry.teamCode)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .containerBackground(for: .widget) {
            ZStack {
                // Base dark color
                Color(white: 0.1)

                // Subtle team color tint
                LinearGradient(
                    colors: [teamColor.opacity(0.2), teamColor.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle top highlight
                LinearGradient(
                    colors: [.white.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

// MARK: - Schedule Match Row

private struct ScheduleMatchRow: View {
    let match: WidgetGame
    let teamCode: String

    private var opponent: WidgetTeam {
        match.homeTeam.code == teamCode ? match.awayTeam : match.homeTeam
    }

    private var isHome: Bool {
        match.homeTeam.code == teamCode
    }

    private var isToday: Bool {
        Calendar.current.isDate(match.date, inSameDayAs: Date())
    }

    private var opponentColor: Color {
        TeamColorCache.color(for: opponent.code)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Date column
            VStack(alignment: .leading, spacing: 1) {
                if isToday {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.yellow)
                } else {
                    Text(match.formatDate().uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Text(match.formatTime())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 55, alignment: .leading)

            // Home/Away pill
            Text(isHome ? "HOME" : "AWAY")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isHome ? .white : .white.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isHome ? .white.opacity(0.2) : .white.opacity(0.1))
                )

            // Opponent
            HStack(spacing: 6) {
                Image("Team/\(opponent.code)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)

                Text(opponent.code)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Opponent color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(opponentColor)
                .frame(width: 4, height: 24)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(isToday ? 0.1 : 0.05))
        )
    }
}

// MARK: - Widget Configuration

struct SHLWidgetTeamSchedule: Widget {
    let kind: String = "SHLWidgetTeamSchedule"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TeamScheduleConfigurationIntent.self,
            provider: TeamScheduleProvider()
        ) { entry in
            TeamScheduleEntryView(entry: entry)
        }
        .configurationDisplayName("Team Schedule")
        .description("View upcoming matches for your team")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .onBackgroundURLSessionEvents { identifier, completion in
            if BackgroundSessionManager.shared.handleBackgroundEvents(
                identifier: identifier, completion: completion) {
                return
            }
            completion()
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    SHLWidgetTeamSchedule()
} timeline: {
    TeamScheduleEntry.placeholder()
}

#Preview("Small - FHC", as: .systemSmall) {
    SHLWidgetTeamSchedule()
} timeline: {
    TeamScheduleEntry.placeholder(teamCode: "FHC", teamName: "Frolunda HC")
}

#Preview("Medium", as: .systemMedium) {
    SHLWidgetTeamSchedule()
} timeline: {
    TeamScheduleEntry.placeholder()
}

#Preview("Medium - No Matches", as: .systemMedium) {
    SHLWidgetTeamSchedule()
} timeline: {
    TeamScheduleEntry(
        date: Date(),
        teamCode: "LHF",
        teamName: "Lulea Hockey",
        matches: [],
        loadError: false
    )
}

#Preview("Error", as: .systemSmall) {
    SHLWidgetTeamSchedule()
} timeline: {
    TeamScheduleEntry.error(teamCode: "LHF", teamName: "Lulea Hockey")
}
