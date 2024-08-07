//
//  SHLWidgetUpcoming.swift
//  SHLWidgetUpcoming
//
//  Created by KibbeWater on 1/4/24.
//

import WidgetKit
import SwiftUI
import HockeyKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            game: .fakeData(),
            leftClr: .red,
            rightClr: .blue,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            game: .fakeData(),
            leftClr: .red,
            rightClr: .blue,
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let matchInfo = MatchInfo()
        try? await matchInfo.getLatest()
        var games = matchInfo.latestMatches
        
        games = games.sorted { a, b in
            a.date < b.date
        }
        
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date.now)!
        
        let game = games.first(where: {!$0.played})

        return Timeline(
            entries: [
                SimpleEntry(
                    date: Date.now,
                    game: game,
                    leftClr: Color(UIImage(named: "Team/\(game?.homeTeam.code ?? "TBD")")?.getColors(quality: .low)?.background ?? UIColor.black),
                    rightClr: Color(UIImage(named: "Team/\(game?.awayTeam.code ?? "TBD")")?.getColors(quality: .low)?.background ?? UIColor.black),
                    configuration: ConfigurationAppIntent()
                )
            ],
            policy: .after(nextUpdateDate)
        )
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    let game: Game?
    let leftClr: Color
    let rightClr: Color
    let configuration: ConfigurationAppIntent
}

struct SHLWidgetUpcomingEntryView : View {
    var entry: Provider.Entry
    
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors: [entry.leftClr, entry.rightClr]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
    }
    
    func FormatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }

    var body: some View {
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
                        Text(FormatDate(game.date))
                            .fontWidth(.condensed)
                        Text(FormatTime(game.date))
                            .fontWeight(.medium)
                            .fontWidth(.condensed)
                            .font(.title2)
                    } else {
                        Text(FormatTime(game.date))
                            .fontWeight(.semibold)
                            .fontWidth(.compressed)
                            .font(.system(size: 42))
                    }
                    Spacer()
                }
                .overlay(alignment: .top) {
                    Text(entry.game?.seriesCode.rawValue ?? "undefined")
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
                .containerBackground(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [entry.leftClr, .clear, .clear, entry.rightClr]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    for: .widget
                )
        }
        .supportedFamilies([.systemMedium])
    }
}

extension ConfigurationAppIntent {
    //fileprivate static var smiley: ConfigurationAppIntent {
        //    let intent = ConfigurationAppIntent()
        //    intent.favoriteEmoji = "😀"
    //    return intent
    //}
}

#Preview(as: .systemMedium) {
    SHLWidgetUpcoming()
} timeline: {
    SimpleEntry(
        date: .now,
        game: .fakeData(),
        leftClr: .red,
        rightClr: .blue,
        configuration: ConfigurationAppIntent()
    )
    SimpleEntry(
        date: .now,
        game: .fakeData(),
        leftClr: .red,
        rightClr: .blue,
        configuration: ConfigurationAppIntent()
    )
}
