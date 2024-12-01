//
//  MatchListViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Foundation
import HockeyKit
import Combine

@MainActor
class MatchListViewModel: ObservableObject {
    @Published var latestMatches: [Game] = []
    @Published var previousMatches: [Game] = []
    @Published var todayMatches: [Game] = []
    @Published var upcomingMatches: [Game] = []
    
    @Published var matchListeners: [String:GameData] = [:]
    private var cancellable: AnyCancellable?

    private let api: HockeyAPI
    
    init(_ api: HockeyAPI) {
        self.api = api
        
        Task {
            try? await refresh()
        }
        
        listenForLiveGame()
    }
    
    deinit {
        cancellable?.cancel()
    }

    func refresh() async throws {
        if let season = try? await api.season.getCurrent() {
            latestMatches = try await api.match.getSeasonSchedule(season)
            
            filterMatches()
            removeUnusedListeners()
        }
    }
    
    private func removeUnusedListeners() {
        var newListeners: [String:GameData] = [:]
        todayMatches.forEach { game in
            guard let listenerData = matchListeners[game.id] else { return }
            newListeners[game.id] = listenerData
        }
        matchListeners = newListeners
    }
    
    private func listenForLiveGame() {
        if let cancellable {
            cancellable.cancel()
        }
        
        cancellable = api.listener.subscribe()
            .sink { [weak self] event in
                if self?.todayMatches.contains(where: { $0.id == event.gameOverview.gameUuid }) == true {
                    self?.matchListeners[event.gameOverview.gameUuid] = event
                }
            }
    }
    

    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current
        
        previousMatches = latestMatches.filter({ $0.date < calendar.startOfDay(for: now) }).map { $0 }
        todayMatches = latestMatches.filter({ calendar.isDateInToday($0.date) }).map { $0 }
        upcomingMatches = latestMatches.filter({ calendar.startOfDay(for: $0.date) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }).map { $0 }
    }
}
