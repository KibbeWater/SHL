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
                HStack {
                    TeamLogoView(teamCode: match.homeTeam.code, size: .custom(42))
                    Text(match.homeTeam.code)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(match.awayTeam.code)
                        .fontWeight(.semibold)
                    TeamLogoView(teamCode: match.awayTeam.code, size: .custom(42))
                }
                .overlay(alignment: .center, content: {
                    VStack {
                        Text(FormatDate(match.date))
                            .font(.callout)
                            .fontWeight(.semibold)
                        Text("vs.")
                            .font(.callout)
                        Spacer()
                    }
                })
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .foregroundStyle(.primary)
            .contextMenu {
                #if !APPCLIP
                ReminderContext(game: match)
                #endif
            }
        }
    }
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
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
