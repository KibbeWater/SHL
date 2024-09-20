//
//  PrevMatchView.swift
//  LHF
//
//  Created by user242911 on 3/24/24.
//

import SwiftUI
import HockeyKit
import ActivityKit
import MapKit

private enum Tabs: String, CaseIterable {
    case summary = "Summary"
    case pbp = "Play by Play"
}

struct MatchView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    let match: Game
    @State private var location: CLLocation?
    @State private var mapImage: UIImage?
    @State private var updater: GameUpdater?
    
    @State private var pbpUpdateTimer: Timer?
    
    @State private var pbpEvents: [PBPEventProtocol] = []
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    @State private var selectedTab: Tabs = .summary
    
    @State private var offset = CGFloat.zero
    
    @State private var activityRunning = false
    
    var trailingButton: some View {
        Button(action: {
            guard let _game = updater?.game else {
                return
            }
            
            do {
                if activityRunning {
                    var activities = Activity<SHLWidgetAttributes>.activities
                    activities = activities.filter({ $0.attributes.id == match.id })
                    
                    let contentState =
                        SHLWidgetAttributes.ContentState(
                            homeScore: _game.homeGoals,
                            awayScore: _game.awayGoals,
                            period: ActivityPeriod(
                                period: _game.time.period,
                                periodEnd: (_game.time.periodEnd ?? Date()).ISO8601Format(),
                                state: ActivityState(rawValue: _game.state.rawValue) ?? .starting
                            )
                        )
                    
                    activities.forEach { activity in
                        Task {
                            await activity.end(
                                ActivityContent(
                                    state: contentState,
                                    staleDate: .now
                                ),
                                dismissalPolicy: .immediate
                            )
                        }
                    }
                    activityRunning = false
                } else {
                    try ActivityUpdater.shared.start(match: _game)
                    activityRunning = true
                }
            } catch let _err {
                print("Unable to start activity \(_err)")
            }
        }) {
            Text(activityRunning ? "Stop Activity" : "Start Activity")
        }
    }
    
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
                        if (match.date < Date.now) {
                            Text(String(updater?.game?.homeGoals ?? match.homeTeam.result))
                                .font(.system(size: 96))
                                .fontWidth(.compressed)
                                .fontWeight(.bold)
                                .foregroundStyle(updater?.game?.homeGoals ?? match.homeTeam.result > updater?.game?.awayGoals ?? match.awayTeam.result ? .white : .white.opacity(0.5))
                                .padding(.bottom, -2)
                            Spacer()
                        }
                        Image("Team/\(match.homeTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .padding(0)
                    }
                    .frame(height: match.date < Date.now ? 172 : 84)
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
                            if match.date < Date.now && match.played {
                                Text(match.shootout ? "OT" : match.overtime ? "OT" : "Full")
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                            } else {
                                Text(Calendar.current.isDate(match.date, inSameDayAs: Date()) ? FormatTime(match.date) : FormatDate(match.date))
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .frame(height: 96)
                                    .foregroundColor(.white)
                                    .overlay(alignment: .bottom) {
                                        if !Calendar.current.isDate(match.date, inSameDayAs: Date()) {
                                            Text(String(FormatTime(match.date)))
                                                .fontWeight(.semibold)
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        }
                                    }
                            }
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
                    .frame(height: match.date < Date.now ? 172 : 84)
                    Spacer()
                    VStack {
                        if match.date < Date.now {
                            Text(String(updater?.game?.awayGoals ?? match.awayTeam.result))
                                .font(.system(size: 96))
                                .fontWidth(.compressed)
                                .fontWeight(.bold)
                                .foregroundStyle(match.awayTeam.result > match.homeTeam.result ? .white : .white.opacity(0.5))
                                .padding(.bottom, -2)
                            Spacer()
                        }
                        Image("Team/\(match.awayTeam.code)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .padding(0)
                    }
                    .frame(height: match.date < Date.now ? 172 : 84)
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
                        if !match.played && match.date < Date.now {
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
                        
                        if match.date < Date.now {
                            VStack {
                                let _: [GoalEvent] = getEvents(pbpEvents, type: GoalEvent.self)
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
                                
                                /* let homeGoals = goals.filter({ $0.eventTeam.teamCode == match.homeTeam.code })
                                let awayGoals = goals.filter({ $0.eventTeam.teamCode == match.awayTeam.code })
                                VersusBar("Save %", homePercent: 1.0-(Float(homeGoals.count) / Float(homeShotsGoal.count + awayShotsGoal.count + goals.count)), awayPercent: 1.0-(Float(awayGoals.count) / Float(homeShotsGoal.count + awayShotsGoal.count + goals.count)), homeColor: homeColor, awayColor: awayColor) */
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack {
                            GeometryReader { geo in
                                if #available(iOS 17.0, *) {
                                    if let _map = mapImage {
                                        Image(uiImage: _map)
                                            .frame(height: 256)
                                            .frame(maxWidth: .infinity)
                                            .onTapGesture {
                                                let url = URL(string: "maps://?q=\(match.venue ?? "")")
                                                if UIApplication.shared.canOpenURL(url!) {
                                                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                                }
                                            }
                                    } else {
                                        ProgressView()
                                            .onAppear {
                                                findVenue(.init(width: geo.size.width, height: geo.size.height))
                                            }
                                            .frame(width: geo.size.width, height: geo.size.height)
                                    }
                                } else {
                                    // TODO: Fallback on earlier versions
                                }
                            }
                        }
                        .frame(height: 256)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                } else if (selectedTab == .pbp) {
                    if match.date > Date.now {
                        VStack {
                            Text("Game has not yet started")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                                .padding(.top)
                        }
                    } else if !pbpEvents.isEmpty {
                        VStack {
                            PBPView(events: $pbpEvents)
                        }
                        .padding(.horizontal)
                    }
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
        .toolbar {
            #if !APPCLIP
            if updater?.game != nil {
                trailingButton
            }
            #endif
        }
        .onAppear {
            loadTeamColors()
            checkActiveActivitites()
        }
        .task {
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
    
    private func checkActiveActivitites() {
        var activities = Activity<SHLWidgetAttributes>.activities
        activities = activities.filter({ $0.attributes.id == match.id })
        
        activityRunning = activities.count != 0
    }
    
    private func loadTeamColors() {
        let _homeKey = "Team/\(match.homeTeam.code.uppercased())"
        let _awayKey = "Team/\(match.awayTeam.code.uppercased())"
        
        if let _homeColor = UIImage(named: _homeKey) {
            if let cache = ColorCache.shared.getColor(forKey: _homeKey) {
                withAnimation {
                    self.homeColor = Color(uiColor: cache)
                }
            } else {
                _homeColor.getColors(quality: .low) { clr in
                    if let _bg = clr?.background {
                        ColorCache.shared.cacheColor(_bg, forKey: _homeKey)
                        withAnimation {
                            self.homeColor = Color(uiColor: _bg)
                        }
                    }
                }
            }
        }
        
        if let _awayColor = UIImage(named: _awayKey) {
            if let cache = ColorCache.shared.getColor(forKey: _awayKey) {
                withAnimation {
                    self.awayColor = Color(uiColor: cache)
                }
            } else {
                _awayColor.getColors(quality: .low) { clr in
                    if let _bg = clr?.background {
                        ColorCache.shared.cacheColor(_bg, forKey: _awayKey)
                        withAnimation {
                            self.awayColor = Color(uiColor: _bg)
                        }
                    }
                }
            }
        }
    }
    
    func findVenue(_ cgSize: CGSize) {
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
                let options: MKMapSnapshotter.Options = .init()
                options.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: venue.placemark.coordinate.latitude,
                        longitude: venue.placemark.coordinate.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                )
                
                options.size = cgSize
                options.mapType = .hybrid
                options.showsBuildings = true
                
                let snapshotter = MKMapSnapshotter(
                    options: options
                )
                
                snapshotter.start { snapshot, error in
                   if let snapshot = snapshot {
                      mapImage = snapshot.image
                   } else if let _error = error {
                      print("Something went wrong \(_error)")
                   }
                }
                
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
        dateFormatter.dateFormat = "HH:mm"
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

#Preview("Previous") {
    MatchView(match: Game.fakeData())
        .environmentObject(MatchInfo())
}

#Preview("Upcoming") {
    MatchView(match: Game(id: Game.fakeData().id, date: Date.distantFuture, played: Game.fakeData().played, overtime: Game.fakeData().overtime, shootout: Game.fakeData().shootout, ssgtUuid: Game.fakeData().ssgtUuid, seriesCode: Game.fakeData().seriesCode, venue: Game.fakeData().venue, homeTeam: Game.fakeData().homeTeam, awayTeam: Game.fakeData().awayTeam))
        .environmentObject(MatchInfo())
}
