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
        HStack {
            ForEach(matches.filter({!$0.played})) { match in
                VStack(spacing: 6) {
                    HStack {
                        Image("Team/\(match.homeTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                        Spacer()
                        VStack {
                            Text(FormatDate(match.date))
                                .font(.callout)
                                .fontWeight(.semibold)
                            Text("vs.")
                                .font(.callout)
                            Spacer()
                        }
                        Spacer()
                        Image("Team/\(match.awayTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    HStack {
                        Spacer()
                        Text(match.venue ?? "TBD")
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(12)
                .frame(width:200)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
    MatchCalendar(matches: [])
}
