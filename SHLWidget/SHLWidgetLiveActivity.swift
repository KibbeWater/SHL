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

struct LHFWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LHFWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                Text("Hello \(String(context.state.homeTeam.score))")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Image("Leagues/LHF")
                        .renderingMode(.original)
                        .resizable().frame(width: 500, height: 500)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(String(context.state.homeTeam.score))")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(String(context.state.homeTeam.score))")
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
