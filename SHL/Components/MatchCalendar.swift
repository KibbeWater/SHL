//
//  MatchCalendar.swift
//  SHL
//
//  Created by KibbeWater on 2024-04-17.
//

import SwiftUI
import HockeyKit

struct MatchCalendar: View {
    var matches: [Game]
    
    var body: some View {
        ForEach(matches.filter({!$0.played})) { match in
            NavigationLink {
                MatchView(match: match)
            } label: {
                HStack {
                    Image("Team/\(match.homeTeam.code)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                    Text(match.homeTeam.code)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(match.awayTeam.code)
                        .fontWeight(.semibold)
                    Image("Team/\(match.awayTeam.code)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
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
        .fakeData(),
        .fakeData(),
        .fakeData(),
        .fakeData(),
    ])
}
