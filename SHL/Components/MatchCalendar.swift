//
//  MatchCalendar.swift
//  SHL
//
//  Created by KibbeWater on 2024-04-17.
//

import SwiftUI

struct MatchCalendar: View {
    var matches: [Match]
    
    var body: some View {
        ForEach(matches.filter({!$0.played})) { match in
            NavigationLink {
                MatchView(match, referrer: "calendar")
            } label: {
                MatchCardCompact(game: match)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                #if !APPCLIP
                ReminderContext(game: match)
                #endif
            }
        }
    }
}

#Preview {
    MatchCalendar(matches: [
        Match.fakeData(),
        Match.fakeData(),
        Match.fakeData(),
        Match.fakeData(),
    ])
}
