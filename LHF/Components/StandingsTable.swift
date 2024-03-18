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
        HStack {
            Text(String(standing.position))
                .padding(.trailing, 18)
            
            Text(standing.team)
            
            Spacer()
            
            Text("\(standing.points)p")
                .padding(.trailing, 24)
            
            Image("Team/\(standing.teamCode)")
                .resizable()
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
    
    init(title: String, league: Leagues, items: Binding<[StandingObj]?>, onRefresh: (() async -> Void)? = nil) {
        self.title = title
        self.league = league
        self._items = items
        self.onRefresh = onRefresh
        self._dict = .constant(Dictionary<Leagues, CacheItem<StandingResults?>>())
    }
    
    init(title: String, league: Leagues, dictionary: Binding<Dictionary<Leagues, CacheItem<StandingResults?>>>, onRefresh: (() async -> Void)? = nil) {
        self.title = title
        self.league = league
        self._dict = dictionary
        self.onRefresh = nil
        self._items = .constant(nil)
    }
    
    func formatStandings(_ dictionary: Dictionary<Leagues, CacheItem<StandingResults?>>) -> [StandingObj]? {
        if let _league = dictionary[league]?.cacheItem {
            return _league.leagueStandings.map { standing in
                return StandingObj(id: UUID().uuidString, position: standing.Rank, logo: standing.info.teamInfo.teamMedia, team: standing.info.teamInfo.teamNames.long, teamCode: standing.info.code ?? "UNK", matches: String(standing.GP), diff: String(standing.Diff), points: String(standing.Points))
            }
        }
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(.accent)
            
            if let _items = _intItems {
                List {
                    ForEach(_items) { item in
                        StandingView(standing: item)
                    }
                }.listStyle(.plain)
                .refreshable {
                    if let _refreshCallback = onRefresh {
                        await _refreshCallback()
                    }
                }
            } else {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(.accent)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: dict) { _, _ in
            let _s = formatStandings(dict)
            _intItems = _s
        }
        .onChange(of: items) { _, _ in
            _intItems = items
        }
    }
}

#Preview {
    VStack {
        Spacer()
        StandingsTable(title: "SHL", league: .SHL, items: .constant([StandingObj(id: "1", position: 1, logo: "https://sportality.cdn.s8y.se/team-logos/lhf1_lhf.svg", team: "Luleå Hockey", teamCode: "LHF", matches: "123", diff: "69", points: "59")])) {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                fatalError("What the fuck?")
            }
        }
        .padding(.horizontal)
        .frame(height: 250)
        Spacer()
        StandingsTable(title: "SHL", league: .SHL, items: .constant(nil))
            .padding(.horizontal)
            .frame(height: 250)
        Spacer()
    }
}
