//
//  PrevMatchView.swift
//  LHF
//
//  Created by user242911 on 3/24/24.
//

import ActivityKit
import MapKit
import PostHog
import SwiftUI

private enum Tabs: String, CaseIterable {
    case summary = "Summary"
    case pbp = "Play by Play"
}

struct MatchView: View {
    let match: Match
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

    init(_ match: Match, referrer: String) {
        self.match = match
        self._viewModel = .init(wrappedValue: .init(match))
        self.referrer = referrer
    }
    
    func TeamLogo(teamCode: String, score: Int, opponentScore: Int) -> some View {
        VStack {
            if match.date < Date.now {
                Text(String(score))
                    .font(.system(size: 96))
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        score > opponentScore ?
                            .white : .white.opacity(0.5)
                    )
                    .padding(.bottom, -2)
                Spacer()
            }
            TeamLogoView(teamCode: teamCode, size: .extraLarge)
                .padding(0)
        }
        .frame(height: !match.isLive() ? 172 : 84)
    }
    
    func GameHeader() -> some View {
        HStack {
            Spacer()
            if let _team = viewModel.home {
                NavigationLink {
                    TeamView(team: _team)
                } label: {
                    TeamLogo(
                        teamCode: viewModel.match?.homeTeam.code ?? match.homeTeam.code,
                        score: viewModel.liveGame?.homeScore ?? viewModel.match?.homeScore ?? match.homeScore,
                        opponentScore: viewModel.liveGame?.awayScore ?? viewModel.match?.awayScore ?? match.awayScore
                    )
                }
            } else {
                TeamLogo(
                    teamCode: viewModel.match?.homeTeam.code ?? match.homeTeam.code,
                    score: viewModel.liveGame?.homeScore ?? viewModel.match?.homeScore ?? match.homeScore,
                    opponentScore: viewModel.liveGame?.awayScore ?? viewModel.match?.awayScore ?? match.awayScore
                )
            }
            
            Spacer()
            
            VStack {
                if let liveGame = viewModel.liveGame {
                    if liveGame.gameState == .ongoing || liveGame.gameState == .paused {
                        Label("P\(liveGame.period)", systemImage: "clock")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.body)
                    }
                    GameTime(liveGame)
                } else {
                    GameTime(viewModel.match ?? match)
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
            
            if let _team = viewModel.away {
                NavigationLink {
                    TeamView(team: _team)
                } label: {
                    TeamLogo(
                        teamCode: viewModel.match?.awayTeam.code ?? match.awayTeam.code,
                        score: viewModel.liveGame?.awayScore ?? viewModel.match?.awayScore ?? match.awayScore,
                        opponentScore: viewModel.liveGame?.homeScore ?? viewModel.match?.homeScore ?? match.homeScore
                    )
                }
            } else {
                TeamLogo(
                    teamCode: viewModel.match?.awayTeam.code ?? match.awayTeam.code,
                    score: viewModel.liveGame?.awayScore ?? viewModel.match?.awayScore ?? match.awayScore,
                    opponentScore: viewModel.liveGame?.homeScore ?? viewModel.match?.homeScore ?? match.homeScore
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
            if let pbpController = viewModel.pbpController,
               let homeTeamId = match.homeTeam.id,
               let awayTeamId = match.awayTeam.id {
                let homePenaltyCount = pbpController.penaltyCount(forTeamID: homeTeamId)
                let awayPenaltyCount = pbpController.penaltyCount(forTeamID: awayTeamId)

                VersusBar("Penalties", homeSide: homePenaltyCount, awaySide: awayPenaltyCount, homeColor: homeColor, awayColor: awayColor)

                if let homeStats = viewModel.matchStats.first(where: { $0.teamID == homeTeamId }),
                   let awayStats = viewModel.matchStats.first(where: { $0.teamID == awayTeamId }) {
                    let homeShotsGoal = homeStats.shotsOnGoal
                    let awayShotsGoal = awayStats.shotsOnGoal
                    VersusBar("Shots on goals", homeSide: homeShotsGoal, awaySide: awayShotsGoal, homeColor: homeColor, awayColor: awayColor)

                    // Count goals for each team
                    let homeGoalCount = pbpController.goalCount(forTeamID: homeTeamId)
                    let awayGoalCount = pbpController.goalCount(forTeamID: awayTeamId)

                    let homeSavesPercent = awayShotsGoal == 0 ? 0 : (Float(awayShotsGoal - awayGoalCount) / Float(awayShotsGoal)) * 100.0
                    let awaySavesPercent = homeShotsGoal == 0 ? 0 : (Float(homeShotsGoal - homeGoalCount) / Float(homeShotsGoal)) * 100.0
                    VersusBar("Save %", homeSide: Int(homeSavesPercent), awaySide: Int(awaySavesPercent), homeColor: homeColor, awayColor: awayColor)

                    let homeFaceoffs = homeStats.faceoffsWon
                    let awayFaceoffs = awayStats.faceoffsWon
                    VersusBar("Won Faceoffs", homeSide: homeFaceoffs, awaySide: awayFaceoffs, homeColor: homeColor, awayColor: awayColor)
                }
            }
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
               match.played == false
            {
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
                                    activities = activities.filter { $0.attributes.id == match.id }
                                    
                                    let contentState =
                                        SHLWidgetAttributes.ContentState(
                                            homeScore: match.homeScore,
                                            awayScore: match.awayScore,
                                            period: .init(
                                                period: 1,
                                                periodEnd: "20:00",
                                                state: .ended
                                            )
                                        )
                                    
                                    for activity in activities {
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
                                    if let liveMatch = viewModel.liveGame {
                                        try ActivityUpdater.shared.start(match: liveMatch)
                                        activityRunning = true
                                    }
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
            } else if let pbpController = viewModel.pbpController, pbpController.hasEvents {
                VStack {
                    ForEach(viewModel.sortedPBPEvents) { event in
                        PBPEventRowView(event: event, match: match)
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
                do {
                    try await viewModel.refresh(hard: true)
                } catch let err {
                    print("MatchView: Failed to refresh: \(err)")
                }
                startTimer()
            }
            .coordinateSpace(name: "scroll")
        }
        .task {
            checkActiveActivitites()
            loadTeamColors()
        }
        .onAppear {
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
            .padding(.horizontal, 24 * (1 - pos))
            .padding(.top, yPosition)
            .ignoresSafeArea(.all)
        )
    }
    
    private func checkActiveActivitites() {
        var activities = Activity<SHLWidgetAttributes>.activities
        activities = activities.filter { $0.attributes.id == match.id }
        
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
            
            if let _game = viewModel.liveGame,
               _game.gameState == .played
            {
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
    MatchView(Match.fakeData(), referrer: "PREVIEW")
}

#Preview("Upcoming") {
    MatchView(Match.fakeData(), referrer: "PREVIEW")
}

#Preview("Live") {
    MatchView(
        Match(
            id: "v2cb2bt9i8",
            date: .now,
            venue: "Coop Norbotten Arena",
            homeTeam: TeamBasic(
                id: "team-1",
                name: "Brynäs",
                code: "BIF"
            ),
            awayTeam: TeamBasic(
                id: "team-2",
                name: "Luleå Hockey",
                code: "LHF"
            ),
            homeScore: 1,
            awayScore: 2,
            state: .ongoing,
            overtime: false,
            shootout: false, externalUUID: ""
        ),
        referrer: "PREVIEW"
    )
}
