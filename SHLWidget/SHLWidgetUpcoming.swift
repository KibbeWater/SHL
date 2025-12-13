//
//  SHLWidgetUpcoming.swift
//  SHLWidget
//
//  Created by KibbeWater on 1/4/24.
//  Redesigned with premium sports aesthetic
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    var date: Date
    let game: WidgetGame?
    let configuration: ConfigurationAppIntent
    let loadError: Bool

    static func placeholder() -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            game: WidgetGame.fakeData(),
            configuration: ConfigurationAppIntent(),
            loadError: false
        )
    }

    static func error(configuration: ConfigurationAppIntent) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            game: nil,
            configuration: configuration,
            loadError: true
        )
    }
}

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.placeholder()
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry.placeholder()
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let api = WidgetAPI()

        let game: WidgetGame?

        // Check if a specific team is selected
        if let teamCode = configuration.teamFilter.teamCode {
            // Get team-specific matches
            let matches = api.getTeamMatches(teamCode: teamCode) ?? []

            if matches.isEmpty {
                // No cached data - show error and retry soon
                let entry = SimpleEntry.error(configuration: configuration)
                let retryDate = Date.now.addingTimeInterval(60)
                return Timeline(entries: [entry], policy: .after(retryDate))
            }

            // Get the first upcoming match for this team
            game = matches.first { $0.date > Date() }
        } else {
            // Featured mode - get all matches and pick featured
            let games = api.getLatestMatches() ?? []

            if games.isEmpty {
                let entry = SimpleEntry.error(configuration: configuration)
                let retryDate = Date.now.addingTimeInterval(60)
                return Timeline(entries: [entry], policy: .after(retryDate))
            }

            game = WidgetFeaturedGame.getFeaturedGame(from: games)
        }

        let entry = SimpleEntry(
            date: Date.now,
            game: game,
            configuration: configuration,
            loadError: game == nil
        )

        let nextUpdate = calculateNextUpdate(for: game)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func calculateNextUpdate(for game: WidgetGame?) -> Date {
        guard let game = game else {
            return Date.now.addingTimeInterval(30 * 60)
        }

        let timeUntilGame = game.date.timeIntervalSince(Date.now)

        if timeUntilGame < 0 {
            return Date.now.addingTimeInterval(30 * 60)
        } else if timeUntilGame < 60 * 60 {
            return Date.now.addingTimeInterval(10 * 60)
        } else if timeUntilGame < 3 * 60 * 60 {
            return Date.now.addingTimeInterval(20 * 60)
        } else if timeUntilGame < 24 * 60 * 60 {
            return Date.now.addingTimeInterval(30 * 60)
        } else {
            return Date.now.addingTimeInterval(60 * 60)
        }
    }
}

// MARK: - Widget Views

struct SHLWidgetUpcomingEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.loadError {
            ErrorView()
        } else {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemSmall:
                SmallWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hockey.puck")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)
            Text("No upcoming matches")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget View

private struct MediumWidgetView: View {
    let entry: SimpleEntry

    private var homeCode: String {
        entry.game?.homeTeam.code ?? "TBD"
    }

    private var awayCode: String {
        entry.game?.awayTeam.code ?? "TBD"
    }

    private var homeColor: Color {
        TeamColorCache.color(for: homeCode)
    }

    private var awayColor: Color {
        TeamColorCache.color(for: awayCode)
    }

    private var isToday: Bool {
        guard let game = entry.game else { return false }
        return Calendar.current.isDate(game.date, inSameDayAs: entry.date)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header bar
            HStack(spacing: 6) {
                Text("UPCOMING")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.5)

                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 3, height: 3)

                if isToday {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.yellow)
                } else if let game = entry.game {
                    Text(game.formatDate().uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Venue
                if let game = entry.game {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(game.venue)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                }
            }
            
            Spacer()

            // Main matchup area
            HStack {
                // Home team - aligned left
                VStack(spacing: 4) {
                    Image("Team/\(homeCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                    VStack(spacing: 1) {
                        Text(homeCode)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("HOME")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(0.5)
                    }
                }

                Spacer()

                // Center - time and vs
                VStack(spacing: 6) {
                    if let game = entry.game {
                        Text(game.formatTime())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize()
                    }

                    Text("VS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()

                // Away team - aligned right
                VStack(spacing: 4) {
                    Image("Team/\(awayCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                    VStack(spacing: 1) {
                        Text(awayCode)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("AWAY")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(0.5)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .containerBackground(for: .widget) {
            ZStack {
                // Base dark gradient
                LinearGradient(
                    colors: [
                        Color(white: 0.15),
                        Color(white: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Team color accents - smooth blend through center
                LinearGradient(
                    stops: [
                        .init(color: homeColor.opacity(0.5), location: 0.0),
                        .init(color: homeColor.opacity(0.2), location: 0.35),
                        .init(color: .clear, location: 0.5),
                        .init(color: awayColor.opacity(0.2), location: 0.65),
                        .init(color: awayColor.opacity(0.5), location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Subtle top glow
                LinearGradient(
                    colors: [.white.opacity(0.05), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

// MARK: - Small Widget View

private struct SmallWidgetView: View {
    let entry: SimpleEntry

    private var homeCode: String {
        entry.game?.homeTeam.code ?? "TBD"
    }

    private var awayCode: String {
        entry.game?.awayTeam.code ?? "TBD"
    }

    private var homeColor: Color {
        TeamColorCache.color(for: homeCode)
    }

    private var awayColor: Color {
        TeamColorCache.color(for: awayCode)
    }

    private var isToday: Bool {
        guard let game = entry.game else { return false }
        return Calendar.current.isDate(game.date, inSameDayAs: entry.date)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Header - centered
            HStack(spacing: 6) {
                Text("UPCOMING")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1.2)

                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 3, height: 3)

                if isToday {
                    Text("TODAY")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.yellow)
                        .tracking(0.5)
                } else if let game = entry.game {
                    Text(game.formatDate().uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(0.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)

            // Teams matchup - centered
            HStack {
                Spacer()

                // Home team
                VStack(spacing: 4) {
                    Image("Team/\(homeCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    Text(homeCode)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize()
                }

                // VS in center
                Text("vs")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                // Away team
                VStack(spacing: 4) {
                    Image("Team/\(awayCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    Text(awayCode)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize()
                }

                Spacer()
            }

            Spacer(minLength: 4)

            // Time and venue
            if let game = entry.game {
                VStack(spacing: 6) {
                    // Time pill - only time, date is in header
                    Text(game.formatTime())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                        )

                    // Venue
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 7))
                        Text(game.venue)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .containerBackground(for: .widget) {
            // Diagonal gradient with smooth blend
            ZStack {
                // Base dark layer
                Color(white: 0.12)

                // Team colors blending diagonally
                LinearGradient(
                    stops: [
                        .init(color: homeColor.opacity(0.7), location: 0.0),
                        .init(color: homeColor.opacity(0.3), location: 0.4),
                        .init(color: awayColor.opacity(0.3), location: 0.6),
                        .init(color: awayColor.opacity(0.7), location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle depth overlay
                LinearGradient(
                    colors: [.white.opacity(0.05), .clear, .black.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Widget Configuration

struct SHLWidgetUpcoming: Widget {
    let kind: String = "SHLWidgetUpcoming"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            SHLWidgetUpcomingEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Match")
        .description("See the next SHL match at a glance")
        .supportedFamilies([.systemMedium, .systemSmall])
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
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry.placeholder()
}

#Preview("Medium - Different Day", as: .systemMedium) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry(
        date: .now,
        game: WidgetGame(
            id: "1",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            venue: "Scandinavium",
            homeTeam: WidgetTeam(name: "Frölunda HC", code: "FHC"),
            awayTeam: WidgetTeam(name: "Luleå Hockey", code: "LHF"),
            homeScore: 0,
            awayScore: 0
        ),
        configuration: ConfigurationAppIntent(),
        loadError: false
    )
}

#Preview("Small", as: .systemSmall) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry.placeholder()
}

#Preview("Small - Different Day", as: .systemSmall) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry(
        date: .now,
        game: WidgetGame(
            id: "1",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            venue: "Coop Norrbotten Arena",
            homeTeam: WidgetTeam(name: "Luleå Hockey", code: "LHF"),
            awayTeam: WidgetTeam(name: "Skellefteå AIK", code: "SKE"),
            homeScore: 0,
            awayScore: 0
        ),
        configuration: ConfigurationAppIntent(),
        loadError: false
    )
}

#Preview("Small - Error", as: .systemSmall) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry.error(configuration: ConfigurationAppIntent())
}
