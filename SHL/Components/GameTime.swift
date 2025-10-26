//
//  GameTime.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 3/3/25.
//

import HockeyKit
import SwiftUI

struct GameTime: View {
    let game: Match?
    let liveGame: GameData?

    init(_ game: Match) {
        self.game = game
        self.liveGame = nil
    }

    init(_ game: GameData) {
        self.liveGame = game
        self.game = nil
    }

    var body: some View {
        if let _game = liveGame {
            switch _game.gameOverview.state {
            case .starting:
                Text("0:00")
            case .ongoing:
                Text(
                    timerInterval: Date.now ... max(Date.now, _game.gameOverview.time.periodEnd ?? Date.now),
                    pauseTime: Date.now,
                    countsDown: true,
                    showsHours: false
                )
            case .onbreak:
                Text("Break")
            case .overtime:
                Text("OT\n\(_game.gameOverview.time.periodTime)")
            case .ended:
                Text("Ended")
            }
        } else if let match = game {
            if match.date > Date.now && match.played {
                Text((match.shootout ?? false) ? "OT" : (match.overtime ?? false) ? "OT" : "Full")
            } else {
                let isToday = Calendar.current.isDate(match.date, inSameDayAs: Date())
                VStack {
                    Text(isToday ? match.formatTime() : match.formatDate())
                    if !isToday {
                        Text(String(match.formatTime()))
                            .font(.title2)
                    }
                }
            }
        }
    }
}

#Preview {
    GameTime(Match.fakeData())
        .fontWeight(.semibold)
        .font(.title)
        .frame(height: 96)
}
