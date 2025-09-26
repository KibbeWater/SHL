//
//  PrevMatchView.swift
//  LHF
//
//  Created by user242911 on 3/24/24.
//

import PostHog
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
    @StateObject var viewModel: MatchViewModel
    
    @State private var pbpUpdateTimer: Timer?
    
    @State private var location: CLLocation?
    @State private var mapImage: UIImage?
    
    @State var homeColor: Color = .black
    @State var awayColor: Color = .black
    
    @State var activityRunning: Bool = false
    
    @State private var selectedTab: Tabs = .summary
    
    @State var pos: CGFloat = 0
    @State private var yPosition: CGFloat = 0
    
    @State var hasLogged = false
    private var referrer: String
    
    init(_ match: Game, referrer: String) {
        self.match = match
        self._viewModel = .init(wrappedValue: .init(match))
        self.referrer = referrer
    }
    
    func TeamLogo(_ team: Team, opponent: Team) -> some View {
        VStack {
            if (match.date < Date.now) {
                Text(String(team.result))
                    .font(.system(size: 96))
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        team.result > opponent.result ?
                            .white : .white.opacity(0.5)
                    )
                    .padding(.bottom, -2)
                Spacer()
            }
            Image("Team/\(team.code.uppercased())")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84, height: 84)
                .padding(0)
        }
        .frame(height: !match.isLive() ? 172 : 84)
    }
    
    func GameHeader() -> some View {
        HStack {
            Spacer()
            NavigationLink {
                if let _team = viewModel.home {
                    TeamView(team: _team)
                } else {
                    ProgressView()
                }
            } label: {
                TeamLogo(
                    viewModel.liveGame?.gameOverview.homeTeam.toTeam() ??
                    viewModel.match?.homeTeam.toTeam() ??
                        match.homeTeam,
                    opponent: viewModel.liveGame?.gameOverview.awayTeam.toTeam() ??
                        viewModel.match?.awayTeam.toTeam() ??
                        match.awayTeam
                )
            }
            
            Spacer()
            
            VStack {
                if let liveGame = viewModel.liveGame {
                    if liveGame.gameOverview.state == .ongoing || liveGame.gameOverview.state == .onbreak {
                        Label("P\(liveGame.gameOverview.time.period)", systemImage: "clock")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.body)
                    }
                    GameTime(liveGame)
                } else {
                    GameTime(match)
                }
                Spacer()
            }
            .fontWeight(.semibold)
            .font(.title)
            .frame(height: 96)
            .foregroundColor(.white)
            .frame(height: match.isLive() ? 172 : 84)
            .frame(maxWidth: .infinity)
            Spacer()
            
            NavigationLink {
                if let _team = viewModel.away {
                    TeamView(team: _team)
                } else {
                    ProgressView()
                }
            } label: {
                TeamLogo(
                    viewModel.liveGame?.gameOverview.awayTeam.toTeam() ??
                        viewModel.match?.awayTeam.toTeam() ??
                        match.awayTeam,
                    
                    opponent: viewModel.liveGame?.gameOverview.homeTeam.toTeam() ??
                        viewModel.match?.homeTeam.toTeam() ??
                        match.homeTeam
                )
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    func TabNavigation() -> some View {
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
    }
    
    func StatsComponent() -> some View {
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
    
    func SummaryTab() -> some View {
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
                                            state: .ended
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
                                    PostHogSDK.shared.capture(
                                        "started_live_activity",
                                        properties: [
                                            "join_type": "match_cta"
                                        ],
                                        userProperties: [
                                            "activity_id": ActivityUpdater.shared.deviceUUID.uuidString
                                        ]
                                    )
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
                StatsComponent()
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
    
    func PBPTab() -> some View {
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
                        PBPView(events: pbp, shouldReverse: viewModel.liveGame != nil)
                    }
                }
                .padding(.horizontal)
            }
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
                GameHeader()
                
                TabNavigation()
                    .padding(.top, 48)
                
                switch selectedTab {
                case .summary:
                    SummaryTab()
                case .pbp:
                    PBPTab()
                }
            }
            .refreshable {
                try? await viewModel.refresh(hard: true)
                startTimer()
            }
            .coordinateSpace(name: "scroll")
        }
        .task {
            checkActiveActivitites()
            loadTeamColors()
        }
        .onAppear {
            viewModel.setAPI(api)
            Task {
                try? await viewModel.refresh()
            }
            startTimer()
            
            // Perform logging
            if !hasLogged {
                PostHogSDK.shared.capture(
                    "match_view_interaction",
                    properties: [
                        "referrer": referrer
                    ],
                    userProperties: [
                        "match_id": match.id
                    ]
                )
                
                PostHogSDK.shared.capture(
                    "team_interaction",
                    properties: [
                        "team_code": match.homeTeam.code
                    ]
                )
                PostHogSDK.shared.capture(
                    "team_interaction",
                    properties: [
                        "team_code": match.awayTeam.code
                    ]
                )
                hasLogged = true
            }
        }
        .getScrollPosition($pos)
        .background(
            ZStack {
                LinearGradient(gradient: Gradient(colors: [homeColor, awayColor]), startPoint: .leading, endPoint: .trailing)
                LinearGradient(gradient: Gradient(colors: [.clear, Color(uiColor: .systemBackground)]), startPoint: .top, endPoint: .bottom)
            }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
                .padding(.horizontal, 24 * (1-pos))
                .padding(.top, yPosition)
                .ignoresSafeArea(.all)
        )

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
                    print("Meow")
                    print(err)
                }
            }
        }
    }
}

#Preview("Previous") {
    MatchView(.fakeData(), referrer: "PREVIEW")
        .environment(\.hockeyAPI, HockeyAPI())
}

#Preview("Upcoming") {
    MatchView(.fakeData(), referrer: "PREVIEW")
        .environment(\.hockeyAPI, HockeyAPI())
}

#Preview("Live") {
    MatchView(.init(
        id: "v2cb2bt9i8",
        date: .now,
        played: false,
        overtime: false,
        shootout: false,
        venue: "Coop Norbotten Arena",
        homeTeam: .init(
            name: "Brynäs",
            code: "BIF",
            result: 1
        ),
        awayTeam: .init(
            name: "Luleå Hockey",
            code: "LHF",
            result: 2
        )
    ), referrer: "PREVIEW")
    .environment(\.hockeyAPI, HockeyAPI())
}
