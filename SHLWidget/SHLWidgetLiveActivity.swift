//
//  LHFWidgetLiveActivity.swift
//  LHFWidget
//
//  Created by user242911 on 1/4/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LHFWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        public var homeTeam: ActivityTeam
        public var awayTeam: ActivityTeam
        
        public struct ActivityTeam: Codable, Hashable {
            public var score: Int
            public var name: String
            public var teamCode: String
            public var icon: URL
        }
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

extension AnyTransition {
    static var moveDown: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top),
            removal: .move(edge: .bottom)
        )
    }
}

struct LHFWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LHFWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                Text("Hello \(String(context.state.homeTeam.score))")
            }
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        VStack {
                            Spacer()
                            Image("Team/\(context.state.homeTeam.teamCode)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 52, height: 52)
                            Spacer()
                        }
                        Spacer()
                        Text(String(context.state.homeTeam.score))
                            .font(.system(size: 48))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(context.state.homeTeam.score >= context.state.awayTeam.score ? .primary : .secondary)
                    }
                    .frame(width: 96)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        Text(String(context.state.awayTeam.score))
                            .font(.system(size: 48))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .transition(.moveDown)
                            .foregroundStyle(context.state.awayTeam.score >= context.state.homeTeam.score ? .primary : .secondary)
                        Spacer()
                        VStack {
                            Spacer()
                            Image("Team/\(context.state.awayTeam.teamCode)")
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
                        Text(Date(), style: .timer)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .font(.title)
                    }
                    Label("P1", systemImage: "clock")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            } compactLeading: {
                HStack {
                    Image("Team/\(context.state.homeTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text(String(context.state.homeTeam.score))
                        .fontWeight(.semibold)
                        .fontWidth(.compressed)
                        .font(.system(size: 22))
                        .foregroundStyle(context.state.homeTeam.score >= context.state.awayTeam.score ? .primary : .secondary)
                }
            } compactTrailing: {
                HStack {
                    Text(String(context.state.awayTeam.score))
                        .fontWeight(.semibold)
                        .fontWidth(.compressed)
                        .font(.system(size: 22))
                        .foregroundStyle(context.state.awayTeam.score >= context.state.homeTeam.score ? .primary : .secondary)
                    Image("Team/\(context.state.awayTeam.teamCode)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
            } minimal: {
                if context.state.homeTeam.score > context.state.awayTeam.score {
                    Text("B")
                } else {
                    Text("A")
                }
                
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LHFWidgetAttributes {
    fileprivate static var preview: LHFWidgetAttributes {
        LHFWidgetAttributes(name: "World")
    }
}

#Preview("Notification", as: .content, using: LHFWidgetAttributes.preview) {
   LHFWidgetLiveActivity()
} contentStates: {
    LHFWidgetAttributes.ContentState(homeTeam: LHFWidgetAttributes.ContentState.ActivityTeam(score: 5, name: "Luleå Hockey", teamCode: "LHF", icon: URL(string: "https://sportality.cdn.s8y.se/team-logos/lhf1_lhf.svg")!), awayTeam: LHFWidgetAttributes.ContentState.ActivityTeam(score: 3, name: "MoDo Hockey", teamCode: "MODO", icon: URL(string: "https://sportality.cdn.s8y.se/team-logos/modo1_modo.svg")!))
}
