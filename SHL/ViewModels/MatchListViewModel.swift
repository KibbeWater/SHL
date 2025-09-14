//
//  MatchListViewModel.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 30/11/24.
//

import Foundation
import HockeyKit
import Combine
import SwiftUI

@MainActor
class MatchListViewModel: ObservableObject {
    private var api: HockeyAPI? = nil
    
    @Published var latestMatches: [Game] = []
    @Published var previousMatches: [Game] = []
    @Published var todayMatches: [Game] = []
    @Published var upcomingMatches: [Game] = []
    
    @Published var matchListeners: [String:GameData] = [:]
    private var cancellable: AnyCancellable?

    deinit {
        cancellable?.cancel()
    }
    
    func setAPI(_ api: HockeyAPI) {
        self.api = api
        
        Task {
            try? await refresh()
        }
        
        listenForLiveGame()
    }

    func refresh(hard: Bool = false) async throws {
        if hard {
            api?.match.resetCache()
        }
        
        if let season = try? await api?.season.getCurrent() {
            guard let series = try? await api?.series.getCurrentSeries() else { return }
            
            latestMatches = try await api?.match.getSeasonSchedule(season, series: series) ?? []
            
            filterMatches()
            removeUnusedListeners()
            api?.listener.requestInitialData(todayMatches.filter({ $0.isLive() || $0.played }).map({ $0.id }))
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
        
        cancellable = api?.listener.subscribe(todayMatches.map({ $0.id }))
            .receive(on: DispatchQueue.main)
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
