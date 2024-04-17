//
//  PrevMatchView.swift
//  LHF
//
//  Created by user242911 on 3/24/24.
//

import SwiftUI
import HockeyKit
import MapKit

private enum Tabs: String, CaseIterable {
    case summary = "Summary"
    case pbp = "Play by Play"
}

struct MatchView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    let match: Game
    @State private var location: CLLocation?
    @State private var updater: GameUpdater?
    
    @State private var pbpUpdateTimer: Timer?
    
    @State private var pbpEvents: [PBPEventProtocol] = []
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    @State private var selectedTab: Tabs = .summary
    
    @State private var offset = CGFloat.zero
    
    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [homeColor, awayColor]), startPoint: .leading, endPoint: .trailing)
                LinearGradient(gradient: Gradient(colors: [.clear, Color(uiColor: .systemBackground)]), startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            
            ScrollView {
                HStack(spacing: 16) {
                    Spacer()
                    VStack {
                        Text(String(updater?.game?.homeGoals ?? match.homeTeam.result))
                            .font(.system(size: 96))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(updater?.game?.homeGoals ?? match.homeTeam.result > updater?.game?.awayGoals ?? match.awayTeam.result ? .white : .white.opacity(0.5))
                            .padding(.bottom, -2)
                        Spacer()
                        Image("Team/\(match.homeTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .padding(0)
                    }
                    .frame(height: 172)
                    Spacer()
                    VStack {
                        if let _game = updater?.game {
                            switch _game.state {
                            case .starting:
                                Text("0:00")
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                            case .ongoing:
                                Text(_game.time.periodTime)
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                            case .onbreak:
                                Text("Break")
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                            case .overtime:
                                Text("OT\n\(_game.time.periodTime)")
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                            case .ended:
                                Text("Ended")
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(match.shootout ? "OT" : match.overtime ? "OT" : match.played ? "Full" : Calendar.current.isDate(match.date, inSameDayAs: Date()) ? FormatTime(match.date) : FormatDate(match.date))
                                .fontWeight(.semibold)
                                .font(.title)
                                .frame(height: 96)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .overlay(alignment: .top, content: {
                        if let _game = updater?.game,
                           _game.state == .ongoing || _game.state == .onbreak {
                            Label("P\(_game.time.period)", systemImage: "clock")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    })
                    .frame(height: 172)
                    Spacer()
                    VStack {
                        Text(String(updater?.game?.awayGoals ?? match.awayTeam.result))
                            .font(.system(size: 96))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(match.awayTeam.result > match.homeTeam.result ? .white : .white.opacity(0.5))
                            .padding(.bottom, -2)
                        Spacer()
                        Image("Team/\(match.awayTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .padding(0)
                    }
                    .frame(height: 172)
                    Spacer()
                }
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self,
                                           value: -$0.frame(in: .named("scroll")).origin.y)
                })
                .onPreferenceChange(ViewOffsetKey.self) {
                    offset = $0
                }
                .padding(.bottom)
                
                HStack {
                    Spacer()
                    ForEach(Tabs.allCases, id: \.self) { tab in
                        Button(tab.rawValue) {
                            selectedTab = tab
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .buttonStyle(.plain)
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                        Spacer()
                    }
                }
                .padding(.vertical)
                
                if (selectedTab == .summary) {
                    VStack {
                        if !match.played && match.date > Date.now {
                            VStack {
                                Text("GAME IS LIVE")
                                    .foregroundStyle(.red)
                                    .fontWeight(.bold)
                                Text("Stats and PBP plays may be updated")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack {
                            let goals: [GoalEvent] = getEvents(pbpEvents, type: GoalEvent.self)
                            let shots: [ShotEvent] = getEvents(pbpEvents, type: ShotEvent.self)
                            let penalties: [PenaltyEvent] = getEvents(pbpEvents, type: PenaltyEvent.self)
                            
                            let homePenalties = penalties.filter({ $0.eventTeam.teamCode == match.homeTeam.code })
                            let awayPenalties = penalties.filter({ $0.eventTeam.teamCode == match.awayTeam.code })
                            VersusBar("Penalties", homeSide: homePenalties.count, awaySide: awayPenalties.count, homeColor: homeColor, awayColor: awayColor)
                            
                            
                            let homeShots = shots.filter({ $0.eventTeam.teamCode == match.homeTeam.code })
                            let awayShots = shots.filter({ $0.eventTeam.teamCode == match.awayTeam.code })
                            VersusBar("Shots", homeSide: homeShots.count, awaySide: awayShots.count, homeColor: homeColor, awayColor: awayColor)
                            
                            let homeShotsGoal = homeShots.filter({ $0.goalSection == 0 })
                            let awayShotsGoal = awayShots.filter({ $0.goalSection == 0 })
                            VersusBar("Shots on goals", homeSide: homeShotsGoal.count, awaySide: awayShotsGoal.count, homeColor: homeColor, awayColor: awayColor)
                            
                            let homeGoals = goals.filter({ $0.eventTeam.teamCode == match.homeTeam.code })
                            let awayGoals = goals.filter({ $0.eventTeam.teamCode == match.awayTeam.code })
                            VersusBar("Save %", homePercent: 1.0-(Float(homeGoals.count) / Float(homeShotsGoal.count + awayShotsGoal.count + goals.count)), awayPercent: 1.0-(Float(awayGoals.count) / Float(homeShotsGoal.count + awayShotsGoal.count + goals.count)), homeColor: homeColor, awayColor: awayColor)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack {
                            if let _loc = location {
                                Map(bounds:
                                        MapCameraBounds(
                                            centerCoordinateBounds:
                                                MKCoordinateRegion(
                                                    center: CLLocationCoordinate2D(latitude: _loc.coordinate.latitude, longitude: _loc.coordinate.longitude),
                                                    span: MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)),
                                            minimumDistance: 500
                                        ),
                                    interactionModes: [.pan, .pitch, .zoom]
                                ) {
                                    Marker(coordinate: CLLocationCoordinate2D(latitude: _loc.coordinate.latitude, longitude: _loc.coordinate.longitude)) {
                                        Text(match.venue ?? "")
                                    }
                                }
                                .onTapGesture {
                                    let url = URL(string: "maps://?q=\(match.venue ?? "")")
                                    if UIApplication.shared.canOpenURL(url!) {
                                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                    }
                                }
                                .mapStyle(.hybrid)
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(height: 256)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                } else if (selectedTab == .pbp) {
                    VStack {
                        PBPView(events: $pbpEvents)
                    }
                    .padding(.horizontal)
                }
            }
            .refreshable {
                pbpUpdateTimer?.invalidate()
                if let _updater = updater,
                   _updater.game == nil || _updater.game?.state != .ended {
                    _updater.refreshPoller()
                    startTimer()
                }
                do {
                    if let events = try await matchInfo.getMatchPBP(match.id) {
                        pbpEvents = events
                    }
                } catch {
                    print("Failed to get play-by-play events")
                }
            }
            .coordinateSpace(name: "scroll")
        }
        .onAppear {
            loadTeamColors()
        }
        .task {
            findVenue()
            if !match.played && match.date < Date.now {
                updater = GameUpdater(gameId: match.id)
                startTimer()
                print("Starting live updater")
            }
            do {
                if let events = try await matchInfo.getMatchPBP(match.id) {
                    pbpEvents = events
                }
            } catch {
                print("Failed to get play-by-play events")
            }
        }
    }
    
    private func loadTeamColors() {
        let _homeColor = Color(UIImage(named: "Team/\(match.homeTeam.code)")?.getColors(quality: .low)?.background ?? UIColor.black)
        let _awayColor = Color(UIImage(named: "Team/\(match.awayTeam.code)")?.getColors(quality: .low)?.background ?? UIColor.black)
        
        withAnimation {
            self.homeColor = _homeColor
            self.awayColor = _awayColor
        }
    }
    
    func findVenue() {
        guard let _venue = match.venue else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(_venue)"
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let venue = response.mapItems.first {
                location = CLLocation(latitude: venue.placemark.coordinate.latitude, longitude: venue.placemark.coordinate.longitude)
            }
        }
    }
    
    func startTimer() {
        print("Starting PBP update timer")
        pbpUpdateTimer?.invalidate()
        pbpUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { timer in
            print("Updating PBP events")
            guard updater != nil else {
                timer.invalidate()
                print("Disabling timer, no updater present")
                return
            }
            
            if let _game = updater?.game,
               _game.state == .ended {
                print("Disabling timer, game has ended")
                timer.invalidate()
                return
            }
            
            Task {
                if let events = try await matchInfo.getMatchPBP(match.id) {
                    pbpEvents = events
                    print("Updated PBP events")
                }
            }
        }
    }
    
    func getEvents<T: PBPEventProtocol>(_ events: [PBPEventProtocol], type: T.Type) -> [T] {
        return events.compactMap { $0 as? T }
    }
    
    
    func FormatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date)
    }
    
    func FormatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    MatchView(match: Game.fakeData())
        .environmentObject(MatchInfo())
}
