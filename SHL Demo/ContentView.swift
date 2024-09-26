//
//  ContentView.swift
//  LHF Demo
//
//  Created by KibbeWater on 3/25/24.
//

import SwiftUI
import HockeyKit

struct ContentView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    @EnvironmentObject var leagueStandings: LeagueStandings
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var sortOrder = [KeyPathComparator(\StandingObj.position)]
    
    @State private var selectedLeaderboard: LeaguePages = .SHL
    @State private var numberOfPages = LeaguePages.allCases.count
    
    var body: some View {
        PromotionBanner()
        ScrollView {
            if let featured = SelectFeaturedMatch() {
                NavigationLink {
                    MatchView(match: featured)
                } label: {
                    MatchOverview(game: featured)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        Text("Match Calendar")
                            .font(.title)
                        .padding(.horizontal)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        MatchCalendar(matches: Array(matchInfo.latestMatches.prefix(5)))
                    }
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical)

                StandingsTable(title: "Table", standings: $leagueStandings.standings)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
            }
        }
        .onAppear {
            Task {
                try await matchInfo.getLatest()
            }
            Task {
                try? await leagueStandings.fetchLeague(skipCache: true)
            }
        }
        .refreshable {
            await Task {
                try? await matchInfo.getLatest()
                let _ = try? await leagueStandings.fetchLeague(skipCache: true)
            }.value
        }
    }
    
    func ReformatStandings(_ standings: StandingResults) -> [StandingObj] {
        return standings.leagueStandings.map { standing in
            return StandingObj(id: UUID().uuidString, position: standing.Rank, logo: standing.info.teamInfo.teamMedia, team: standing.info.teamInfo.teamNames.long, teamCode: standing.info.code ?? "UNK", matches: String(standing.GP), diff: String(standing.Diff), points: String(standing.Points))
        }
    }
    
    func SelectFeaturedMatch() -> Game? {
        let lastPlayed = matchInfo.latestMatches.last(where: { $0.played })
        
        return lastPlayed
    }
    
    func RemainingTimeUntil(_ targetDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        let estimatedEndTimeString = formatter.string(from: targetDate)
        return estimatedEndTimeString
    }
}
    
extension ContentView {
    enum LeaguePages: Int, CaseIterable {
        case SHL
        case SDHL
    }
}

struct PageControlView<T: RawRepresentable>: UIViewRepresentable where T.RawValue == Int {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var currentPage: T
    @Binding var numberOfPages: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context)
    -> UIPageControl {
        let uiView = UIPageControl()
        uiView.pageIndicatorTintColor = colorScheme == .dark ? nil : .black.withAlphaComponent(0.2)
        uiView.currentPageIndicatorTintColor = colorScheme == .dark ? nil : .black
        uiView.backgroundStyle = .automatic
        uiView.currentPage = currentPage.rawValue
        uiView.numberOfPages = numberOfPages
        uiView.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged), for: .valueChanged)
        return uiView
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentPage.rawValue
        uiView.numberOfPages = numberOfPages
        updateColors(uiView)
    }
    
    private func updateColors(_ uiView: UIPageControl) {
            uiView.pageIndicatorTintColor = colorScheme == .dark ? nil : .black.withAlphaComponent(0.2)
            uiView.currentPageIndicatorTintColor = colorScheme == .dark ? nil : .black
            uiView.backgroundStyle = .automatic
        }
}

extension PageControlView {
    final class Coordinator: NSObject {
        var parent: PageControlView
        
        init(_ parent: PageControlView) {
            self.parent = parent
        }
        
        @objc func valueChanged(sender: UIPageControl) {
            guard let currentPage = T(rawValue: sender.currentPage) else {
                return
            }

            withAnimation {
                parent.currentPage = currentPage
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MatchInfo())
        .environmentObject(LeagueStandings())
}
