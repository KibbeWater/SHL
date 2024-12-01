//
//  StandingsTable.swift
//  LHF
//
//  Created by user242911 on 1/2/24.
//

import SwiftUI
import HockeyKit

struct StandingObj: Identifiable, Equatable {
    public var id: String
    public var position: Int
    public var logo: String
    public var team: String
    public var teamCode: String
    public var matches: String
    public var diff: String
    public var points: String
}

struct StandingView: View {
    public var standing: StandingObj
    
    var body: some View {
        Group {
            Text(String(standing.position))
            
            Text(standing.team)
            
            Text("\(standing.points)p")
                .padding(.trailing, 24)
            
            Image("Team/\(standing.teamCode)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }
}

struct StandingsTable: View {
    public var title: String
    public var items: [StandingObj]
    
    public var onRefresh: (() async -> Void)? = nil
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
            }
            LazyVGrid(columns: [
                GridItem(.fixed(24), alignment: .topLeading),
                GridItem(.flexible(), alignment: .topLeading),
                GridItem(.flexible(), alignment: .topTrailing),
                GridItem(.fixed(32), alignment: .topTrailing),
            ]) {
                ForEach(items) { item in
                    StandingView(standing: item)
                }
            }
        }
        .padding()
    }
}

#Preview {
    VStack {
        StandingsTable(
            title: "Table",
            items: [
                StandingObj(
                    id: "1",
                    position: 1,
                    logo: "https://sportality.cdn.s8y.se/team-logos/lhf1_lhf.svg",
                    team: "Luleå Hockey",
                    teamCode: "LHF",
                    matches: "123",
                    diff: "69",
                    points: "59"
                )
            ]
        )
        .padding(.horizontal)
        .frame(height: 250)
    }
}
