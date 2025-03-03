//
//  GameTime.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 3/3/25.
//

import SwiftUI
import HockeyKit

struct GameTime: View {
    let game: Game?
    let liveGame: GameData?
    
    init(_ game: Game) {
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
                Text(_game.gameOverview.time.periodTime)
            case .onbreak:
                Text("Break")
            case .overtime:
                Text("OT\n\(_game.gameOverview.time.periodTime)")
            case .ended:
                Text("Ended")
            }
        } else if let match = game {
            if match.date > Date.now && match.played {
                Text(match.shootout ? "OT" : match.overtime ? "OT" : "Full")
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
    GameTime(Game.fakeData())
        .fontWeight(.semibold)
        .font(.title)
        .frame(height: 96)
}
