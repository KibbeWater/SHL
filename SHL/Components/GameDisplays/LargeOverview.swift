//
//  LargeOverview.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 27/9/24.
//

import MapKit
import SwiftUI
import HockeyKit

struct LargeOverview: View {
    var game: Game
    var liveGame: GameOverview?
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    @State var mapImage: UIImage? = nil
    @State var location: CLLocation? = nil
    
    private func loadTeamColors() {
        game.awayTeam.getTeamColor { clr in
            withAnimation {
                self.awayColor = clr
            }
        }
        
        game.homeTeam.getTeamColor { clr in
            withAnimation {
                self.homeColor = clr
            }
        }
    }
    
    init(game: Game, liveGame: GameOverview? = nil) {
        self.game = game
        if game.id == liveGame?.gameUuid {
            self.liveGame = liveGame
        }
    }
    
    func isHomeLeading() -> Bool {
        liveGame?.homeGoals ?? game.homeTeam.result > liveGame?.awayGoals ?? game.awayTeam.result
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDate(game.date, inSameDayAs: Date())
    }
    
    var gameStatusTag: some View {
        if let _liveGame = liveGame {
            switch _liveGame.state {
            case .starting:
                return Text("Starting")
            case .ongoing:
                return Text("P\(_liveGame.time.period): \(_liveGame.time.periodTime)")
            case .onbreak:
                return Text("P\(_liveGame.time.period): Pause")
            case .overtime:
                return Text("OT: \(_liveGame.time.periodTime)")
            case .ended:
                return Text("Ended")
            }
        } else {
            return Text(game.shootout ? "Shootout" : game.overtime ? "Overtime" : game.played ? "Full-Time" : isToday() ? game.formatTime() : game.formatDate())
                .fontWeight(.medium)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                HStack(spacing: 34) {
                    Image("Team/\(game.homeTeam.code.uppercased())")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                    Text(String(liveGame?.homeGoals ?? game.homeTeam.result))
                        .font(.system(size: 100))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            isHomeLeading() ? .white : .white.opacity(0.5)
                        )
                        .padding(.bottom, -2)
                }
                Spacer()
                VStack {
                    gameStatusTag
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 34) {
                    Text(String(liveGame?.awayGoals ?? game.awayTeam.result))
                        .font(.system(size: 100))
                        .fontWidth(.compressed)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            !isHomeLeading() ? .white : .white.opacity(0.5)
                        )
                        .padding(.bottom, -2)
                    Image("Team/\(game.awayTeam.code.uppercased())")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                }
            }
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "pin.fill")
                            .resizable()
                            .foregroundStyle(.red)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                        Text("Location")
                            .foregroundStyle(Color(uiColor: .white))
                            .fontWeight(.bold)
                            .font(.system(size: 32))
                        Spacer()
                    }
                    GeometryReader { geo in
                        if let _mapImage = mapImage {
                            Image(uiImage: _mapImage)
                                .frame(width: geo.size.width, height: 128)
                                .onTapGesture {
                                    let url = URL(string: "maps://?q=\(game.venue ?? "")")
                                    if UIApplication.shared.canOpenURL(url!) {
                                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                    }
                                }
                        } else {
                            VStack {
                                ProgressView()
                                    .onAppear {
                                        game.findVenue(.init(width: geo.size.width, height: 128)) { res in
                                            switch res {
                                            case .success(let success):
                                                location = success.1
                                                mapImage = success.0.image
                                            case .failure(let failure):
                                                print(failure)
                                            }
                                        }
                                    }
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: 128)
                }
                Spacer()
            }
        }
        .padding()
        .padding(.top, 42)
        .onAppear(perform: {
            loadTeamColors()
        })
        .background(
            LinearGradient(
                gradient: Gradient(colors: [homeColor, awayColor]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

#Preview {
    VStack {
        LargeOverview(game: .fakeData())
        Spacer()
    }
}
