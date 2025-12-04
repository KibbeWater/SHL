//
//  GameTime.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 3/3/25.
//

import SwiftUI

struct GameTime: View {
    let game: Match?
    let liveGame: LiveMatch?

    init(_ game: Match) {
        self.game = game
        self.liveGame = nil
    }

    init(_ game: LiveMatch) {
        self.liveGame = game
        self.game = nil
    }

    var body: some View {
        if let _game = liveGame {
            switch _game.gameState {
            case .scheduled:
                Text("0:00")
            case .ongoing:
                Text(
                    timerInterval: Date.now ... max(Date.now, _game.periodEnd),
                    pauseTime: Date.now,
                    countsDown: true,
                    showsHours: false
                )
            case .paused:
                Text("Break")
            case .played:
                Text("Ended")
            }
        } else if let match = game {
            if match.date < Date.now && match.state == .played {
                Text((match.shootout ?? false) ? "OT" : (match.overtime ?? false) ? "OT" : "Full-Time")
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
