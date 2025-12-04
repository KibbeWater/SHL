//
//  SHLWidgetUpcoming.swift
//  SHLWidgetUpcoming
//
//  Created by KibbeWater on 1/4/24.
//

import WidgetKit
import SwiftUI
import UIKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            game: WidgetGame.fakeData(),
            leftClr: .red,
            rightClr: .blue,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            game: WidgetGame.fakeData(),
            leftClr: .red,
            rightClr: .blue,
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let api = WidgetAPI()
        let games = (try? await api.getLatestMatches()) ?? []

        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date.now)!

        let game = WidgetFeaturedGame.getFeaturedGame(from: games)

        return Timeline(
            entries: [
                SimpleEntry(
                    date: Date.now,
                    game: game,
                    leftClr: getTeamColor(code: game?.homeTeam.code ?? "TBD"),
                    rightClr: getTeamColor(code: game?.awayTeam.code ?? "TBD"),
                    configuration: ConfigurationAppIntent()
                )
            ],
            policy: .after(nextUpdateDate)
        )
    }

    private func getTeamColor(code: String) -> Color {
        if let image = UIImage(named: "Team/\(code)") {
            return Color(image.getColors(quality: .low)?.background ?? UIColor.black)
        }
        return .black
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    let game: WidgetGame?
    let leftClr: Color
    let rightClr: Color
    let configuration: ConfigurationAppIntent
}

struct SHLWidgetUpcomingEntryView : View {
    var entry: Provider.Entry
    
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors: [entry.leftClr, .clear, .clear, entry.rightClr]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemMedium {
            HStack {
                VStack {
                    HStack {
                        VStack {
                            Spacer()
                            Image("Team/\(entry.game?.homeTeam.code ?? "TBD")")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                            Spacer()
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(entry.game?.homeTeam.name ?? "TBD")
                            .font(.system(size: 10))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 72)
                    }
                    .frame(width: 96)
                }
                .padding(.vertical, 8)
                Spacer()
                if let game = entry.game {
                    VStack {
                        Spacer()
                        if !Calendar.current.isDate(entry.game?.date ?? Date.now, inSameDayAs: entry.date) {
                            Text(game.formatDate())
                                .fontWidth(.condensed)
                            Text(game.formatTime())
                                .fontWeight(.medium)
                                .fontWidth(.condensed)
                                .font(.title2)
                        } else {
                            Text(game.formatTime())
                                .fontWeight(.semibold)
                                .fontWidth(.compressed)
                                .font(.system(size: 42))
                        }
                        Spacer()
                    }
                    .overlay(alignment: .top) {
                        // Text(entry.game?.seriesCode.rawValue ?? "undefined")
                        Text("SHL")
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                Spacer()
                VStack {
                    HStack {
                        VStack {
                            Spacer()
                            Image("Team/\(entry.game?.awayTeam.code ?? "TBD")")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                            Spacer()
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(entry.game?.awayTeam.name ?? "TBD")
                            .font(.system(size: 10))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 72)
                    }
                    .frame(width: 96)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, -12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(
                gradient,
                for: .widget
            )
        } else if family == .systemSmall {
            VStack {
                HStack {
                    Image("Team/\(entry.game?.homeTeam.code ?? "TBD")")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                    Text(entry.game?.homeTeam.name ?? "TBD")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text(entry.game?.awayTeam.name ?? "TBD")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                    Image("Team/\(entry.game?.awayTeam.code ?? "TBD")")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                }
                HStack {
                    VStack(alignment: .leading) {
                        if let game = entry.game {
                            if !Calendar.current.isDate(entry.game?.date ?? Date.now, inSameDayAs: entry.date) {
                                Text("Date")
                                    .font(.system(size: 14))
                                Text(game.formatDate())
                                    .font(.system(size: 10))
                            } else {
                                Text("Time")
                                    .font(.system(size: 16))
                                Text(game.formatTime())
                                    .font(.system(size: 10))
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Venue")
                            .font(.system(size: 14))
                        if let game = entry.game {
                            Text(game.venue)
                                .font(.system(size: 10))
                        }
                        Spacer()
                    }
                }
            }
            .containerBackground(
                LinearGradient(
                    gradient: Gradient(
                        colors: [entry.leftClr, .clear, .clear, entry.rightClr]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                for: .widget
            )
        }
    }
}

extension View {
    @ViewBuilder func widgetBackground<T: View>(@ViewBuilder content: () -> T) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget, content: content)
        }else {
            background(content())
        }
    }
}

struct SHLWidgetUpcoming: Widget {
    let kind: String = "SHLWidgetUpcoming"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SHLWidgetUpcomingEntryView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemSmall])
    }
}

extension ConfigurationAppIntent {
    //fileprivate static var smiley: ConfigurationAppIntent {
        //    let intent = ConfigurationAppIntent()
        //    intent.favoriteEmoji = "😀"
    //    return intent
    //}
}

#Preview("Medium", as: .systemMedium) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry(
        date: .now,
        game: WidgetGame.fakeData(),
        leftClr: .red,
        rightClr: .blue,
        configuration: ConfigurationAppIntent()
    )
    SimpleEntry(
        date: .now,
        game: WidgetGame.fakeData(),
        leftClr: .red,
        rightClr: .blue,
        configuration: ConfigurationAppIntent()
    )
}

#Preview("Small", as: .systemSmall) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry(
        date: .now,
        game: WidgetGame.fakeData(),
        leftClr: .red,
        rightClr: .blue,
        configuration: ConfigurationAppIntent()
    )
    SimpleEntry(
        date: .now,
        game: WidgetGame.fakeData(),
        leftClr: .red,
        rightClr: .blue,
        configuration: ConfigurationAppIntent()
    )
}
