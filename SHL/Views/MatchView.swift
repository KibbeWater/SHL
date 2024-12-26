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
    @Environment(\.hockeyAPI) private var api: HockeyAPI
    
    let match: Game
    
    @State private var location: CLLocation?
    @State private var mapImage: UIImage?
    
    @State private var pbpUpdateTimer: Timer?
    
    @State private var homeColor: Color = .black // Default color, updated on appear
    @State private var awayColor: Color = .black // Default color, updated on appear
    
    @State private var selectedTab: Tabs = .summary
    
    @State private var offset = CGFloat.zero
    
    @State private var activityRunning = false
    
    @StateObject var viewModel: MatchViewModel
    
    init(_ match: Game) {
        self.match = match
        self._viewModel = .init(wrappedValue: .init(match))
    }
    
    var trailingButton: some View {
        Button(action: {
            
        }) {
            Text(activityRunning ? "Stop Activity" : "Start Activity")
        }
    }
    
    var statComponent: some View {
        VStack {
            let goals: [GoalEvent]? = viewModel.pbp?.getEvents(ofType: PBPEventType.goal)
            // let shots: [ShotEvent] = getEvents(pbpEvents, type: ShotEvent.self)
            let penalties: [PenaltyEvent]? = viewModel.pbp?.getEvents(ofType: PBPEventType.penalty)
            
            let homePenalties = penalties?.filter({ $0.eventTeam.teamCode == match.homeTeam.code }) ?? []
            let awayPenalties = penalties?.filter({ $0.eventTeam.teamCode == match.awayTeam.code }) ?? []
            VersusBar("Penalties", homeSide: homePenalties.count, awaySide: awayPenalties.count, homeColor: homeColor, awayColor: awayColor)
            
            let homeShotsGoal = viewModel.matchStats?.home.getStat(for: GameStatKey.shotsOnGoal) ?? 0
            let awayShotsGoal = viewModel.matchStats?.away.getStat(for: GameStatKey.shotsOnGoal) ?? 0
            VersusBar("Shots on goals", homeSide: homeShotsGoal, awaySide: awayShotsGoal, homeColor: homeColor, awayColor: awayColor)
            
            let homeGoals = goals?.filter({ $0.eventTeam.teamCode == match.homeTeam.code }) ?? []
            let awayGoals = goals?.filter({ $0.eventTeam.teamCode == match.awayTeam.code }) ?? []
            let homeSavesPercent = homeShotsGoal == 0 ? 0 : (Float(homeShotsGoal - awayGoals.count) / Float(homeShotsGoal)) * 100.0
            let awaySavesPercent = awayShotsGoal == 0 ? 0 : (Float(awayShotsGoal - homeGoals.count) / Float(awayShotsGoal)) * 100.0
            VersusBar("Save %", homeSide: Int(homeSavesPercent), awaySide: Int(awaySavesPercent), homeColor: homeColor, awayColor: awayColor)
            
            let homeFaceoffs = viewModel.matchStats?.home.getStat(for: .wonFaceoffs) ?? 0
            let awayFaceoffs = viewModel.matchStats?.away.getStat(for: .wonFaceoffs) ?? 0
            VersusBar("Won Faceoffs", homeSide: homeFaceoffs, awaySide: awayFaceoffs, homeColor: homeColor, awayColor: awayColor)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var summaryTab: some View {
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
            
            if match.date > Date.now.addingTimeInterval((8 * 60 * 60) * -1),
               match.played == false {
                HStack {
                    if !match.isLive() {
                        VStack {
                            Text("Follow the game when it starts")
                                .fontWeight(.bold)
                            Text("You will be notified when game starts")
                                .font(.footnote)
                        }
                        .multilineTextAlignment(.leading)
                    } else {
                        VStack {
                            Text("Follow the game")
                                .fontWeight(.bold)
                            Text("Match stats and results will be displayed on your lockscreen")
                                .font(.footnote)
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button(activityRunning ? "Stop" : "Join") {
                            do {
                                if activityRunning {
                                    var activities = Activity<SHLWidgetAttributes>.activities
                                    activities = activities.filter({ $0.attributes.id == match.id })
                                    
                                    let contentState =
                                    SHLWidgetAttributes.ContentState(
                                        homeScore: match.homeTeam.result,
                                        awayScore: match.awayTeam.result,
                                        period: .init(
                                            period: 1,
                                            periodEnd: "20:00",
                                            state: .intermission
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
                                    try ActivityUpdater.shared.start(match: match)
                                    activityRunning = true
                                }
                            } catch let _err {
                                print("Unable to start activity \(_err)")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if match.date < Date.now {
                statComponent
            }
            
            VStack {
                GeometryReader { geo in
                    if #available(iOS 17.0, *) {
                        if let _map = mapImage {
                            Image(uiImage: _map)
                                .frame(height: 256)
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    let url = URL(string: "maps://?q=\(match.venue)")
                                    if UIApplication.shared.canOpenURL(url!) {
                                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                    }
                                }
                        } else {
                            ProgressView()
                                .onAppear {
                                    match.findVenue(.init(width: geo.size.width, height: geo.size.height)) { res in
                                        switch res {
                                        case .success(let success):
                                            location = success.1
                                            mapImage = success.0.image
                                        case .failure(let failure):
                                            print(failure)
                                        }
                                    }
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
    }
    
    var pbpTab: some View {
        VStack {
            if match.date > Date.now {
                VStack {
                    Text("Game has not yet started")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.top)
                }
            } else if viewModel.pbp?.events.isEmpty == false {
                VStack {
                    if let pbp = viewModel.pbp {
                        PBPView(events: pbp)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    var gameHeader: some View {
        HStack(spacing: 16) {
            Spacer()
            NavigationLink {
                if let _team = viewModel.home {
                    TeamView(team: _team)
                } else {
                    ProgressView()
                }
            } label: {
                VStack {
                    if (match.date < Date.now) {
                        Text(String(viewModel.liveGame?.gameOverview.homeGoals ?? match.homeTeam.result))
                            .font(.system(size: 96))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                viewModel.liveGame?.gameOverview.homeGoals ?? match.homeTeam.result >
                                viewModel.liveGame?.gameOverview.awayGoals ?? match.awayTeam.result ?
                                    .white : .white.opacity(0.5)
                            )
                            .padding(.bottom, -2)
                        Spacer()
                    }
                    Image("Team/\(match.homeTeam.code.uppercased())")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 84, height: 84)
                        .padding(0)
                }
                .frame(height: match.date < Date.now ? 172 : 84)
            }
            
            Spacer()
            
            VStack {
                if let _game = viewModel.liveGame {
                    switch _game.gameOverview.state {
                    case .starting:
                        Text("0:00")
                            .fontWeight(.semibold)
                            .font(.title)
                            .frame(height: 96)
                            .foregroundColor(.white)
                    case .ongoing:
                        Text(_game.gameOverview.time.periodTime)
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
                        Text("OT\n\(_game.gameOverview.time.periodTime)")
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
                        let isToday = Calendar.current.isDate(match.date, inSameDayAs: Date())
                        Text(isToday ? match.formatTime() : match.formatDate())
                            .fontWeight(.semibold)
                            .font(.title)
                            .frame(height: 96)
                            .foregroundColor(.white)
                            .overlay(alignment: .bottom) {
                                if !isToday {
                                    Text(String(match.formatTime()))
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
                if let _game = viewModel.liveGame,
                   _game.gameOverview.state == .ongoing || _game.gameOverview.state == .onbreak {
                    Label("P\(_game.gameOverview.time.period)", systemImage: "clock")
                        .foregroundStyle(.white.opacity(0.5))
                }
            })
            .frame(height: match.date < Date.now ? 172 : 84)
            .frame(maxWidth: .infinity)
            Spacer()
            
            NavigationLink {
                if let _team = viewModel.away {
                    TeamView(team: _team)
                } else {
                    ProgressView()
                }
            } label: {
                VStack {
                    if match.date < Date.now {
                        Text(String(viewModel.liveGame?.gameOverview.awayGoals ?? match.awayTeam.result))
                            .font(.system(size: 96))
                            .fontWidth(.compressed)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                viewModel.liveGame?.gameOverview.homeGoals ?? match.homeTeam.result <
                                viewModel.liveGame?.gameOverview.awayGoals ?? match.awayTeam.result ?
                                    .white : .white.opacity(0.5)
                            )
                            .padding(.bottom, -2)
                        Spacer()
                    }
                    Image("Team/\(match.awayTeam.code.uppercased())")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 84, height: 84)
                        .padding(0)
                }
                .frame(height: match.date < Date.now ? 172 : 84)
            }
            
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
    }
    
    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [homeColor, awayColor]), startPoint: .leading, endPoint: .trailing)
                LinearGradient(gradient: Gradient(colors: [.clear, Color(uiColor: .systemBackground)]), startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            
            ScrollView {
                gameHeader
                
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
                    summaryTab
                } else if (selectedTab == .pbp) {
                    pbpTab
                }
            }
            .refreshable {
                try? await viewModel.refresh()
                startTimer()
            }
            .coordinateSpace(name: "scroll")
        }
        /* .toolbar {
            #if !APPCLIP
            if viewModel.liveGame != nil {
                trailingButton
            }
            #endif
        } */
        .onAppear {
            loadTeamColors()
            checkActiveActivitites()
        }
        .task {
            startTimer()
            viewModel.setAPI(api)
        }
    }
    
    private func checkActiveActivitites() {
        var activities = Activity<SHLWidgetAttributes>.activities
        activities = activities.filter({ $0.attributes.id == match.id })
        
        activityRunning = activities.count != 0
    }
    
    private func loadTeamColors() {
        match.awayTeam.getTeamColor { clr in
            withAnimation {
                self.awayColor = clr
            }
        }
        
        match.homeTeam.getTeamColor { clr in
            withAnimation {
                self.homeColor = clr
            }
        }
    }
    
    func startTimer() {
        print("Starting PBP update timer")
        pbpUpdateTimer?.invalidate()
        pbpUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { timer in
            if !match.isLive() {
                print("Disabling timer, match is not live")
                timer.invalidate()
                return
            }
            
            if let _game = viewModel.liveGame?.gameOverview,
               _game.state == .ended {
                print("Disabling timer, game has ended")
                timer.invalidate()
                return
            }
            
            Task {
                do {
                    try await viewModel.refreshPBP()
                } catch let err {
                    print(err)
                }
            }
        }
    }
    
    func getEvents<T: PBPEventProtocol>(_ events: [PBPEventProtocol], type: T.Type) -> [T] {
        return events.compactMap { $0 as? T }
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
    MatchView(.fakeData())
        .environment(\.hockeyAPI, HockeyAPI())
}

#Preview("Upcoming") {
    MatchView(.fakeData())
        .environment(\.hockeyAPI, HockeyAPI())
}
