//
//  StandingsTable.swift
//  LHF
//
//  Created by user242911 on 1/2/24.
//

import SwiftUI
import HockeyKit
import SVGKit

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
            
            SVGImageView(url: URL(string: standing.logo)!, size: CGSize(width: 32, height: 32))
                .frame(width: 32, height: 32)
        }
    }
}

struct StandingsTable: View {
    public var title: String
    @Binding public var items: [StandingObj]?
    
    public var onRefresh: (() async -> Void)? = nil
    
    init(title: String, items: Binding<[StandingObj]?> = .constant(nil)) {
        self.title = title
        self._items = items
    }
    
    init(title: String)
    
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
            
            if let _items = items {
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
    }
}

#Preview {
    VStack {
        Spacer()
        StandingsTable(title: "SHL", items: .constant([StandingObj(id: "1", position: 1, logo: "https://sportality.cdn.s8y.se/team-logos/lhf1_lhf.svg", team: "Luleå Hockey", matches: "123", diff: "69", points: "59")])) {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                fatalError("What the fuck?")
            }
        }
        .padding(.horizontal)
        .frame(height: 250)
        Spacer()
        StandingsTable(title: "SHL", items: .constant(nil))
            .padding(.horizontal)
            .frame(height: 250)
        Spacer()
    }
}
