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
    @Binding public var items: [StandingObj]?
    @Binding public var dict: Dictionary<Leagues, CacheItem<StandingResults?>>
    @State private var _intItems: [StandingObj]?
    private var league: Leagues
    
    public var onRefresh: (() async -> Void)? = nil
    
    init(title: String, league: Leagues, items: Binding<[StandingObj]?>) {
        self.title = title
        self.league = league
        self._items = items
        self.onRefresh = nil
        self._dict = .constant(Dictionary<Leagues, CacheItem<StandingResults?>>())
    }
    
    init(title: String, league: Leagues, dictionary: Binding<Dictionary<Leagues, CacheItem<StandingResults?>>>) {
        self.title = title
        self.league = league
        self._dict = dictionary
        self.onRefresh = nil
        self._items = .constant(nil)
    }
    
    func formatStandings(_ dictionary: Dictionary<Leagues, CacheItem<StandingResults?>>) -> [StandingObj]? {
        if let _league = dictionary[league]?.cacheItem {
            return _league.leagueStandings.map { standing in
                return StandingObj(id: UUID().uuidString, position: standing.Rank, logo: standing.info.teamInfo.teamMedia, team: standing.info.teamInfo.teamNames.long, teamCode: standing.info.code ?? "TBD", matches: String(standing.GP), diff: String(standing.Diff), points: String(standing.Points))
            }
        }
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
            }
            if let _items = _intItems {
                LazyVGrid(columns: [
                    GridItem(.fixed(24), alignment: .topLeading),
                    GridItem(.flexible(), alignment: .topLeading),
                    GridItem(.flexible(), alignment: .topTrailing),
                    GridItem(.fixed(32), alignment: .topTrailing),
                ]) {
                    ForEach(_items) { item in
                        StandingView(standing: item)
                    }
                }
            } else {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onChange(of: dict) { _ in
            let _s = formatStandings(dict)
            _intItems = _s
        }
        .onChange(of: items) { _ in
            _intItems = items
        }
    }
}

#Preview {
    VStack {
        StandingsTable(title: "Table", league: .SHL, items: .constant([StandingObj(id: "1", position: 1, logo: "https://sportality.cdn.s8y.se/team-logos/lhf1_lhf.svg", team: "Luleå Hockey", teamCode: "LHF", matches: "123", diff: "69", points: "59")]))
            .padding(.horizontal)
            .frame(height: 250)
    }
}
