//
//  SHLWidgetStandings.swift
//  SHLWidget
//
//  Shows current SHL league standings
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct StandingsEntry: TimelineEntry {
    let date: Date
    let standings: [WidgetStanding]
    let highlightTeamCode: String?
    let loadError: Bool

    static func placeholder() -> StandingsEntry {
        StandingsEntry(
            date: Date(),
            standings: Self.fakeStan,
            highlightTeamCode: nil,
            loadError: false
        )
    }

    static func error() -> StandingsEntry {
        StandingsEntry(
            date: Date(),
            standings: [],
            highlightTeamCode: nil,
            loadError: true
        )
    }

    static var fakeStandings: [WidgetStanding] {
        [
            WidgetStanding(id: "1", rank: 1, team: WidgetTeam(name: "Lulea Hockey", code: "LHF"), points: 72, gamesPlayed: 40, goalDifference: 45, wins: 28, losses: 8, overtimeLosses: 4),
            WidgetStanding(id: "2", rank: 2, team: WidgetTeam(name: "Frolunda HC", code: "FHC"), points: 68, gamesPlayed: 40, goalDifference: 38, wins: 26, losses: 10, overtimeLosses: 4),
            WidgetStanding(id: "3", rank: 3, team: WidgetTeam(name: "Skelleftea AIK", code: "SKE"), points: 61, gamesPlayed: 40, goalDifference: 22, wins: 23, losses: 13, overtimeLosses: 4),
            WidgetStanding(id: "4", rank: 4, team: WidgetTeam(name: "Farjestad BK", code: "FBK"), points: 58, gamesPlayed: 40, goalDifference: 18, wins: 22, losses: 14, overtimeLosses: 4),
            WidgetStanding(id: "5", rank: 5, team: WidgetTeam(name: "Rogle BK", code: "RBK"), points: 55, gamesPlayed: 40, goalDifference: 12, wins: 20, losses: 16, overtimeLosses: 4),
            WidgetStanding(id: "6", rank: 6, team: WidgetTeam(name: "Vaxjo Lakers", code: "VLH"), points: 52, gamesPlayed: 40, goalDifference: 8, wins: 19, losses: 17, overtimeLosses: 4),
            WidgetStanding(id: "7", rank: 7, team: WidgetTeam(name: "Djurgarden IF", code: "DIF"), points: 49, gamesPlayed: 40, goalDifference: 5, wins: 18, losses: 18, overtimeLosses: 4),
            WidgetStanding(id: "8", rank: 8, team: WidgetTeam(name: "HV71", code: "HV71"), points: 46, gamesPlayed: 40, goalDifference: -2, wins: 17, losses: 19, overtimeLosses: 4),
            WidgetStanding(id: "9", rank: 9, team: WidgetTeam(name: "Malmo Redhawks", code: "MIF"), points: 43, gamesPlayed: 40, goalDifference: -8, wins: 16, losses: 20, overtimeLosses: 4),
            WidgetStanding(id: "10", rank: 10, team: WidgetTeam(name: "Orebro HK", code: "OHK"), points: 40, gamesPlayed: 40, goalDifference: -15, wins: 14, losses: 22, overtimeLosses: 4),
            WidgetStanding(id: "11", rank: 11, team: WidgetTeam(name: "Linkoping HC", code: "LHC"), points: 38, gamesPlayed: 40, goalDifference: -18, wins: 13, losses: 23, overtimeLosses: 4),
            WidgetStanding(id: "12", rank: 12, team: WidgetTeam(name: "Brynas IF", code: "BIF"), points: 35, gamesPlayed: 40, goalDifference: -25, wins: 12, losses: 24, overtimeLosses: 4)
        ]
    }

    private static var fakeStan: [WidgetStanding] {
        fakeStandings
    }
}

// MARK: - Timeline Provider

struct StandingsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StandingsEntry {
        StandingsEntry.placeholder()
    }

    func snapshot(for configuration: StandingsConfigurationIntent, in context: Context) async -> StandingsEntry {
        StandingsEntry.placeholder()
    }

    func timeline(for configuration: StandingsConfigurationIntent, in context: Context) async -> Timeline<StandingsEntry> {
        let api = WidgetAPI()

        // Get cached data (triggers background refresh if stale)
        let standings = api.getStandings() ?? []

        // Handle empty standings
        guard !standings.isEmpty else {
            let entry = StandingsEntry.error()
            let retryDate = Date.now.addingTimeInterval(60) // Retry in 1 minute
            return Timeline(entries: [entry], policy: .after(retryDate))
        }

        let highlightCode = configuration.highlightTeam.teamCode

        let entry = StandingsEntry(
            date: Date.now,
            standings: standings,
            highlightTeamCode: highlightCode,
            loadError: false
        )

        // Update every hour
        let nextUpdate = Date.now.addingTimeInterval(60 * 60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Widget Views

struct StandingsWidgetEntryView: View {
    var entry: StandingsEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.loadError {
            StandingsErrorView()
        } else {
            switch family {
            case .systemMedium:
                MediumStandingsView(entry: entry)
            case .systemLarge:
                LargeStandingsView(entry: entry)
            default:
                MediumStandingsView(entry: entry)
            }
        }
    }
}

// MARK: - Error View

private struct StandingsErrorView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text("Unable to load standings")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(white: 0.1)
        }
    }
}

// MARK: - Medium Standings View

private struct MediumStandingsView: View {
    let entry: StandingsEntry

    /// Dynamically calculated season string (e.g., "2024/25")
    private static var currentSeasonString: String {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        // Season starts in September, so Aug and earlier = previous season
        let seasonStartYear = month >= 9 ? year : year - 1
        let seasonEndYear = seasonStartYear + 1
        return "\(seasonStartYear)/\(String(seasonEndYear).suffix(2))"
    }

    private var hasHighlight: Bool {
        guard let code = entry.highlightTeamCode else { return false }
        return entry.standings.contains { $0.team.code == code && $0.rank > 4 }
    }

    private var topStandings: [WidgetStanding] {
        Array(entry.standings.prefix(hasHighlight ? 3 : 4))
    }

    private var highlightedStanding: WidgetStanding? {
        guard let code = entry.highlightTeamCode else { return nil }
        return entry.standings.first { $0.team.code == code && $0.rank > 4 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Text("STANDINGS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.5)

                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 3, height: 3)

                Text(Self.currentSeasonString)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
            .padding(.bottom, 8)

            // Column headers
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 16, alignment: .center)
                Text("TEAM")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                Text("GP")
                    .frame(width: 26, alignment: .center)
                Text("W")
                    .frame(width: 22, alignment: .center)
                Text("L")
                    .frame(width: 22, alignment: .center)
                Text("PTS")
                    .frame(width: 30, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.bottom, 4)

            // Standings rows
            VStack(spacing: 1) {
                ForEach(topStandings) { standing in
                    TableStandingRow(
                        standing: standing,
                        isHighlighted: standing.team.code == entry.highlightTeamCode,
                        compact: true
                    )
                }

                // Highlighted team if not in top
                if let highlighted = highlightedStanding {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(height: 1)
                        Text("•••")
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.3))
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 1)

                    TableStandingRow(
                        standing: highlighted,
                        isHighlighted: true,
                        compact: true
                    )
                }
            }
        }
        .padding(.horizontal, hasHighlight ? 16 : 12)
        .padding(.top, hasHighlight ? 10 : 6)
        .padding(.bottom, hasHighlight ? 10 : 6)
        .containerBackground(for: .widget) {
            ZStack {
                Color(white: 0.1)
                LinearGradient(
                    colors: [.white.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

// MARK: - Large Standings View

private struct LargeStandingsView: View {
    let entry: StandingsEntry

    /// Dynamically calculated season string (e.g., "2024/25")
    private static var currentSeasonString: String {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        // Season starts in September, so Aug and earlier = previous season
        let seasonStartYear = month >= 9 ? year : year - 1
        let seasonEndYear = seasonStartYear + 1
        return "\(seasonStartYear)/\(String(seasonEndYear).suffix(2))"
    }

    private var hasHighlight: Bool {
        guard let code = entry.highlightTeamCode else { return false }
        return entry.standings.contains { $0.team.code == code && $0.rank > 11 }
    }

    private var topStandings: [WidgetStanding] {
        Array(entry.standings.prefix(hasHighlight ? 10 : 11))
    }

    private var highlightedStanding: WidgetStanding? {
        guard let code = entry.highlightTeamCode else { return nil }
        return entry.standings.first { $0.team.code == code && $0.rank > 11 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Text("STANDINGS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.5)

                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 3, height: 3)

                Text("SHL \(Self.currentSeasonString)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
            .padding(.bottom, 8)

            // Column headers
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 18, alignment: .center)
                Text("TEAM")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 6)
                Text("GP")
                    .frame(width: 28, alignment: .center)
                Text("W")
                    .frame(width: 24, alignment: .center)
                Text("L")
                    .frame(width: 24, alignment: .center)
                Text("+/-")
                    .frame(width: 30, alignment: .center)
                Text("PTS")
                    .frame(width: 32, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.bottom, 4)

            // Standings rows
            VStack(spacing: 0) {
                ForEach(topStandings) { standing in
                    LargeTableStandingRow(
                        standing: standing,
                        isHighlighted: standing.team.code == entry.highlightTeamCode
                    )

                    // Playoff line after 6th
                    if standing.rank == 6 {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(.yellow.opacity(0.3))
                                .frame(height: 1)
                            Text("PLAYOFFS")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.yellow.opacity(0.6))
                                .tracking(0.5)
                            Rectangle()
                                .fill(.yellow.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Highlighted team if not in top
                if let highlighted = highlightedStanding {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(height: 1)
                        Text("•••")
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.3))
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 2)

                    LargeTableStandingRow(
                        standing: highlighted,
                        isHighlighted: true
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, hasHighlight ? 18 : 16)
        .padding(.top, hasHighlight ? 12 : 8)
        .padding(.bottom, 8)
        .containerBackground(for: .widget) {
            ZStack {
                Color(white: 0.1)
                LinearGradient(
                    colors: [.white.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

// MARK: - Table Standing Row

private struct TableStandingRow: View {
    let standing: WidgetStanding
    let isHighlighted: Bool
    let compact: Bool

    private var teamColor: Color {
        TeamColorCache.color(for: standing.team.code)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            Text("\(standing.rank)")
                .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(standing.rank <= 6 ? .white : .white.opacity(0.5))
                .frame(width: compact ? 16 : 20, alignment: .center)

            // Team logo and code
            HStack(spacing: compact ? 5 : 8) {
                Image("Team/\(standing.team.code)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: compact ? 16 : 22, height: compact ? 16 : 22)

                Text(standing.team.code)
                    .font(.system(size: compact ? 10 : 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, compact ? 4 : 6)

            // Stats columns
            Group {
                Text("\(standing.gamesPlayed)")
                    .frame(width: compact ? 26 : 32, alignment: .center)

                Text("\(standing.wins ?? 0)")
                    .frame(width: compact ? 22 : 28, alignment: .center)

                Text("\(standing.losses ?? 0)")
                    .frame(width: compact ? 22 : 28, alignment: .center)

                if !compact {
                    Text(standing.goalDifference >= 0 ? "+\(standing.goalDifference)" : "\(standing.goalDifference)")
                        .foregroundStyle(standing.goalDifference >= 0 ? .green.opacity(0.8) : .red.opacity(0.8))
                        .frame(width: 32, alignment: .center)
                }

                Text("\(standing.points)")
                    .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: compact ? 30 : 36, alignment: .trailing)
            }
            .font(.system(size: compact ? 9 : 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, compact ? 4 : 6)
        .padding(.horizontal, compact ? 4 : 6)
        .background(
            Group {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(teamColor.opacity(0.25))
                } else if standing.rank <= 6 {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.white.opacity(0.05))
                }
            }
        )
    }
}

// MARK: - Large Table Standing Row

private struct LargeTableStandingRow: View {
    let standing: WidgetStanding
    let isHighlighted: Bool

    private var teamColor: Color {
        TeamColorCache.color(for: standing.team.code)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            Text("\(standing.rank)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(standing.rank <= 6 ? .white : .white.opacity(0.5))
                .frame(width: 18, alignment: .center)

            // Team logo and code
            HStack(spacing: 6) {
                Image("Team/\(standing.team.code)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)

                Text(standing.team.code)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)

            // Stats columns
            Group {
                Text("\(standing.gamesPlayed)")
                    .frame(width: 28, alignment: .center)

                Text("\(standing.wins ?? 0)")
                    .frame(width: 24, alignment: .center)

                Text("\(standing.losses ?? 0)")
                    .frame(width: 24, alignment: .center)

                Text(standing.goalDifference >= 0 ? "+\(standing.goalDifference)" : "\(standing.goalDifference)")
                    .foregroundStyle(standing.goalDifference >= 0 ? .green.opacity(0.8) : .red.opacity(0.8))
                    .frame(width: 30, alignment: .center)

                Text("\(standing.points)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 32, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            Group {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(teamColor.opacity(0.25))
                } else if standing.rank <= 6 {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.white.opacity(0.05))
                }
            }
        )
    }
}

// MARK: - Widget Configuration

struct SHLWidgetStandings: Widget {
    let kind: String = "SHLWidgetStandings"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StandingsConfigurationIntent.self,
            provider: StandingsProvider()
        ) { entry in
            StandingsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SHL Standings")
        .description("View the current SHL league standings")
        .supportedFamilies([.systemMedium, .systemLarge])
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

#Preview("Medium", as: .systemMedium) {
    SHLWidgetStandings()
} timeline: {
    StandingsEntry.placeholder()
}

#Preview("Medium - Highlighted", as: .systemMedium) {
    SHLWidgetStandings()
} timeline: {
    StandingsEntry(
        date: Date(),
        standings: StandingsEntry.fakeStandings,
        highlightTeamCode: "RBK",
        loadError: false
    )
}

#Preview("Large", as: .systemLarge) {
    SHLWidgetStandings()
} timeline: {
    StandingsEntry.placeholder()
}

#Preview("Large - Highlighted", as: .systemLarge) {
    SHLWidgetStandings()
} timeline: {
    StandingsEntry(
        date: Date(),
        standings: StandingsEntry.fakeStandings,
        highlightTeamCode: "FHC",
        loadError: false
    )
}

#Preview("Error", as: .systemMedium) {
    SHLWidgetStandings()
} timeline: {
    StandingsEntry.error()
}
