//
//  LHFWidgetLiveActivity.swift
//  LHFWidget
//
//  Created by user242911 on 1/4/24.
//

import ActivityKit
import WidgetKit
import SwiftUI
import HockeyKit

extension AnyTransition {
    static var moveDown: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top),
            removal: .move(edge: .bottom)
        )
    }
}

struct SHLWidgetLiveActivity: Widget {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SHLWidgetAttributes.self) { context in
            HStack {
                HStack {
                    VStack {
                        Spacer()
                        Image("Team/\(context.attributes.homeTeam.teamCode)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 52)
                        Spacer()
                    }
                    Spacer()
                    Text(String(context.state.homeScore))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.homeScore >= context.state.awayScore ? .primary : .secondary)
                }
                .frame(width: 96)
                
                Spacer()
                
                VStack {
                    HStack {
                        let _periodEnd = ISODateToStr(dateString: context.state.period.periodEnd)
                        switch context.state.period.state {
                        case .ended:
                            Text("Ended")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        case .onbreak:
                            Text(_periodEnd, style: .timer)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        case .ongoing, .overtime:
                            Text(_periodEnd, style: .timer)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        case .starting:
                            Text("0:00")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.vertical, 10)
                .overlay(alignment: .top) {
                    if context.state.period.state == .onbreak {
                        Label("Pause", systemImage: "clock")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    } else {
                        Label("P\(context.state.period.period)", systemImage: "clock")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                Spacer()
                
                HStack {
                    Text(String(context.state.awayScore))
                        .font(.system(size: 48))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .transition(.moveDown)
                        .foregroundStyle(context.state.awayScore >= context.state.homeScore ? .primary : .secondary)
                    Spacer()
                    VStack {
                        Spacer()
                        Image("Team/\(context.attributes.awayTeam.teamCode)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 52)
                        Spacer()
                    }
                }
                .frame(width: 96)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        VStack {
                            Spacer()
                            Image("Team/\(context.attributes.homeTeam.teamCode)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 52, height: 52)
                            Spacer()
                        }
                        Spacer()
                        Text(String(context.state.homeScore))
                            .font(.system(size: 48))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(context.state.homeScore >= context.state.awayScore ? .primary : .secondary)
                    }
                    .frame(width: 96)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        Text(String(context.state.awayScore))
                            .font(.system(size: 48))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .transition(.moveDown)
                            .foregroundStyle(context.state.awayScore >= context.state.homeScore ? .primary : .secondary)
                        Spacer()
                        VStack {
                            Spacer()
                            Image("Team/\(context.attributes.awayTeam.teamCode)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 52, height: 52)
                            Spacer()
                        }
                    }
                    .frame(width: 96)
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        let _periodEnd = ISODateToStr(dateString: context.state.period.periodEnd)
                        switch context.state.period.state {
                        case .ended:
                            Text("Ended")
                                .font(.title)
                                .fontWeight(.semibold)
                        case .onbreak:
                            Text(_periodEnd, style: .timer)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .font(.title)
                                .fontWeight(.semibold)
                        case .ongoing, .overtime:
                            Text(_periodEnd, style: .timer)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .font(.title)
                                .fontWeight(.semibold)
                        case .starting:
                            Text("0:00")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                    }
                    if context.state.period.state == .onbreak {
                        Label("Pause", systemImage: "clock")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        Label("P\(context.state.period.period)", systemImage: "clock")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            } compactLeading: {
                HStack {
                    Image("Team/\(context.attributes.homeTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text(String(context.state.homeScore))
                        .fontWeight(.semibold)
                        .fontWidth(.compressed)
                        .font(.system(size: 22))
                        .foregroundStyle(context.state.homeScore >= context.state.awayScore ? .primary : .secondary)
                }
            } compactTrailing: {
                HStack {
                    Text(String(context.state.awayScore))
                        .fontWeight(.semibold)
                        .fontWidth(.compressed)
                        .font(.system(size: 22))
                        .foregroundStyle(context.state.awayScore >= context.state.homeScore ? .primary : .secondary)
                    Image("Team/\(context.attributes.awayTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
            } minimal: {
                if context.state.homeScore > context.state.awayScore {
                    Image("Team/\(context.attributes.homeTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else if context.state.homeScore < context.state.awayScore {
                    Image("Team/\(context.attributes.awayTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Text("SHL")
                        .fontWeight(.bold)
                }
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
    
    func ISODateToStr(dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return formatter.date(from: dateString) ?? Date()
    }
}

extension SHLWidgetAttributes {
    fileprivate static var preview: SHLWidgetAttributes {
        SHLWidgetAttributes(id: "123", homeTeam: ActivityTeam(name: "Luleå Hockey", teamCode: "LHF"), awayTeam: ActivityTeam(name: "MODO Hockey", teamCode: "MODO"))
    }
}

#Preview("Notification", as: .content, using: SHLWidgetAttributes.preview) {
   SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.ContentState(homeScore: 5, awayScore: 3, period: ActivityPeriod(period: 2, periodEnd: Calendar.current.date(byAdding: .minute, value: 1, to: Date.now)?.ISO8601Format(.Strategy(includingFractionalSeconds: true)) ?? "2024-03-27T19:55:54.364Z", state: .ongoing))
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: SHLWidgetAttributes.preview) {
   SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.ContentState(homeScore: 5, awayScore: 3, period: ActivityPeriod(period: 2, periodEnd: Calendar.current.date(byAdding: .minute, value: 1, to: Date.now)?.ISO8601Format(.Strategy(includingFractionalSeconds: true)) ?? "2024-03-27T19:55:54.364Z", state: .ongoing))
}

#Preview("Compact", as: .dynamicIsland(.compact), using: SHLWidgetAttributes.preview) {
   SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.ContentState(homeScore: 5, awayScore: 3, period: ActivityPeriod(period: 2, periodEnd: Calendar.current.date(byAdding: .minute, value: 1, to: Date.now)?.ISO8601Format(.Strategy(includingFractionalSeconds: true)) ?? "2024-03-27T19:55:54.364Z", state: .ongoing))
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: SHLWidgetAttributes.preview) {
   SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.ContentState(homeScore: 5, awayScore: 3, period: ActivityPeriod(period: 2, periodEnd: Calendar.current.date(byAdding: .minute, value: 1, to: Date.now)?.ISO8601Format(.Strategy(includingFractionalSeconds: true)) ?? "2024-03-27T19:55:54.364Z", state: .ongoing))
}
