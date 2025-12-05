//
//  MatchView.swift
//  SHL
//
//  Created by user242911 on 3/24/24.
//

import ActivityKit
import MapKit
import PostHog
import SwiftUI

private enum MatchTab: String, CaseIterable {
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
    @State private var selectedTab: MatchTab = .summary

    @State var hasLogged = false
    private var referrer: String

    init(_ match: Match, referrer: String) {
        self.match = match
        self._viewModel = .init(wrappedValue: .init(match))
        self.referrer = referrer
    }

    // MARK: - Computed Properties

    private var currentMatch: Match {
        viewModel.match ?? match
    }

    private var homeScore: Int {
        viewModel.liveGame?.homeScore ?? currentMatch.homeScore
    }

    private var awayScore: Int {
        viewModel.liveGame?.awayScore ?? currentMatch.awayScore
    }

    private var isLive: Bool {
        match.isLive()
    }

    private var hasStarted: Bool {
        match.date < Date.now
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if hasStarted || isLive {
                        tabPicker
                    }

                    contentSection
                }
                .padding(.bottom, 32)
            }
            .refreshable {
                do {
                    try await viewModel.refresh(hard: true)
                } catch {
                    print("MatchView: Failed to refresh: \(error)")
                }
                startTimer()
            }
        }
        .task {
            checkActiveActivities()
            loadTeamColors()
        }
        .onAppear {
            Task {
                try? await viewModel.refresh()
            }
            startTimer()
            logAnalytics()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [homeColor, awayColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.clear, Color(uiColor: .systemBackground)],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Status badge above score (for live/final states)
            if let liveGame = viewModel.liveGame {
                gameStatusBadge(liveGame)
            } else if match.played {
                finalBadge
            }

            // Teams and Score
            HStack(alignment: .center, spacing: 16) {
                // Home Team
                teamLogo(
                    code: currentMatch.homeTeam.code,
                    team: viewModel.home
                )

                Spacer()

                // Score / Time Center
                scoreCenterView

                Spacer()

                // Away Team
                teamLogo(
                    code: currentMatch.awayTeam.code,
                    team: viewModel.away
                )
            }
            .padding(.horizontal, 24)

            // Countdown badge for upcoming games
            if !hasStarted && viewModel.liveGame == nil {
                countdownBadge
            }

            // Venue
            venueLabel
        }
        .padding(.top, 16)
    }

    private func teamLogo(code: String, team: Team?) -> some View {
        Group {
            if let team = team {
                NavigationLink {
                    TeamView(team: team)
                } label: {
                    teamLogoContent(code: code)
                }
                .buttonStyle(.plain)
            } else {
                teamLogoContent(code: code)
            }
        }
    }

    private func teamLogoContent(code: String) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(teamCode: code, size: .extraLarge)

            Text(code)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var scoreCenterView: some View {
        VStack(spacing: 4) {
            if hasStarted {
                HStack(spacing: 12) {
                    Text("\(homeScore)")
                        .foregroundStyle(homeScore >= awayScore ? .white : .white.opacity(0.5))

                    Text("-")
                        .foregroundStyle(.white.opacity(0.4))

                    Text("\(awayScore)")
                        .foregroundStyle(awayScore >= homeScore ? .white : .white.opacity(0.5))
                }
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .fontWidth(.compressed)
            } else {
                // Future game - show date and time prominently
                VStack(spacing: 6) {
                    Text(match.date.formatted(.dateTime.weekday(.wide)))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)

                    Text(match.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(match.date.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }

    private func gameStatusBadge(_ liveGame: LiveMatch) -> some View {
        HStack(spacing: 6) {
            if liveGame.gameState == .ongoing {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
            }

            Text(statusText(for: liveGame))
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func statusText(for liveGame: LiveMatch) -> String {
        switch liveGame.gameState {
        case .ongoing:
            return "LIVE • P\(liveGame.period)"
        case .paused:
            return "INTERMISSION"
        default:
            return "FINAL"
        }
    }

    private var countdownBadge: some View {
        let timeUntilGame = match.date.timeIntervalSince(Date.now)
        let days = Int(timeUntilGame / 86400)
        let hours = Int((timeUntilGame.truncatingRemainder(dividingBy: 86400)) / 3600)

        return HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.caption)

            if days > 0 {
                Text("\(days)d \(hours)h until puck drop")
                    .font(.caption)
                    .fontWeight(.semibold)
            } else if hours > 0 {
                Text("\(hours)h until puck drop")
                    .font(.caption)
                    .fontWeight(.semibold)
            } else {
                Text("Starting soon")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var finalBadge: some View {
        Text("FINAL")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var venueLabel: some View {
        if let venue = match.venue {
            Label(venue, systemImage: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(MatchTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        switch selectedTab {
        case .summary:
            summaryContent
        case .pbp:
            pbpContent
        }
    }

    // MARK: - Summary Content

    private var summaryContent: some View {
        VStack(spacing: 16) {
            if isLive || (!match.played && hasStarted) {
                liveActivityCard
            }

            if hasStarted {
                statsCard
            }

            // Future game content
            if !hasStarted {
                upcomingGameInfoCard
            }

            if match.venue != nil {
                venueMapCard
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Upcoming Game Content

    private var upcomingGameInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Game Info", systemImage: "hockey.puck.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                // Date & Time Row
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Date & Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(match.date.formatted(.dateTime.weekday(.wide).month(.wide).day().hour().minute()))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                }

                Divider()

                // Venue Row
                if let venue = match.venue {
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Venue")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(venue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        Spacer()
                    }

                    Divider()
                }

                // Matchup Row
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "sportscourt.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Matchup")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(currentMatch.homeTeam.name) vs \(currentMatch.awayTeam.name)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var liveActivityCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activityRunning ? "Following Game" : "Follow Live")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(activityRunning ?
                     "Live updates on your Lock Screen" :
                     "Get live updates on your Lock Screen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                toggleLiveActivity()
            } label: {
                Text(activityRunning ? "Stop" : "Start")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(activityRunning ? .red : .blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Game Stats")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            if let pbpController = viewModel.pbpController,
               let homeTeamId = match.homeTeam.id,
               let awayTeamId = match.awayTeam.id {

                let homePenalties = pbpController.penaltyCount(forTeamID: homeTeamId)
                let awayPenalties = pbpController.penaltyCount(forTeamID: awayTeamId)

                VersusBar("Penalties", homeSide: homePenalties, awaySide: awayPenalties,
                         homeColor: homeColor, awayColor: awayColor)

                if let homeStats = viewModel.matchStats.first(where: { $0.teamID == homeTeamId }),
                   let awayStats = viewModel.matchStats.first(where: { $0.teamID == awayTeamId }) {

                    VersusBar("Shots on Goal", homeSide: homeStats.shotsOnGoal,
                             awaySide: awayStats.shotsOnGoal, homeColor: homeColor, awayColor: awayColor)

                    let homeGoals = pbpController.goalCount(forTeamID: homeTeamId)
                    let awayGoals = pbpController.goalCount(forTeamID: awayTeamId)

                    let homeSavePercent = awayStats.shotsOnGoal == 0 ? 0 :
                        Int((Float(awayStats.shotsOnGoal - awayGoals) / Float(awayStats.shotsOnGoal)) * 100)
                    let awaySavePercent = homeStats.shotsOnGoal == 0 ? 0 :
                        Int((Float(homeStats.shotsOnGoal - homeGoals) / Float(homeStats.shotsOnGoal)) * 100)

                    VersusBar("Save %", homeSide: homeSavePercent, awaySide: awaySavePercent,
                             homeColor: homeColor, awayColor: awayColor)

                    VersusBar("Faceoffs Won", homeSide: homeStats.faceoffsWon,
                             awaySide: awayStats.faceoffsWon, homeColor: homeColor, awayColor: awayColor)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var venueMapCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Venue")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()

                Button {
                    openInMaps()
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            GeometryReader { geo in
                if let mapImage = mapImage {
                    Image(uiImage: mapImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .onTapGesture {
                            openInMaps()
                        }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            loadMap(size: geo.size)
                        }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - PBP Content

    private var pbpContent: some View {
        VStack(spacing: 12) {
            if !hasStarted {
                emptyStateView(
                    icon: "clock",
                    title: "Game Not Started",
                    message: "Play by play will be available once the game begins"
                )
            } else if let pbpController = viewModel.pbpController, pbpController.hasEvents {
                ForEach(viewModel.sortedPBPEvents) { event in
                    PBPEventRowView(event: event, match: match)
                }
            } else {
                emptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Events Yet",
                    message: "Events will appear here as the game progresses"
                )
            }
        }
        .padding(.horizontal)
    }

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func toggleLiveActivity() {
        do {
            if activityRunning {
                stopLiveActivity()
            } else {
                try startLiveActivity()
            }
        } catch {
            print("Unable to toggle activity: \(error)")
        }
    }

    private func startLiveActivity() throws {
        PostHogSDK.shared.capture(
            "started_live_activity",
            properties: ["join_type": "match_cta"],
            userProperties: ["activity_id": ActivityUpdater.shared.deviceUUID.uuidString]
        )

        if let liveMatch = viewModel.liveGame {
            try ActivityUpdater.shared.start(match: liveMatch)
            activityRunning = true
        }
    }

    private func stopLiveActivity() {
        var activities = Activity<SHLWidgetAttributes>.activities
        activities = activities.filter { $0.attributes.id == match.id }

        let contentState = SHLWidgetAttributes.ContentState(
            homeScore: match.homeScore,
            awayScore: match.awayScore,
            period: .init(period: 1, periodEnd: "20:00", state: .ended)
        )

        for activity in activities {
            Task {
                await activity.end(
                    ActivityContent(state: contentState, staleDate: .now),
                    dismissalPolicy: .immediate
                )
            }
        }
        activityRunning = false
    }

    private func openInMaps() {
        guard let venue = match.venue,
              let url = URL(string: "maps://?q=\(venue)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    private func loadMap(size: CGSize) {
        match.findVenue(size) { result in
            switch result {
            case .success(let (snapshot, loc)):
                location = loc
                mapImage = snapshot.image
            case .failure(let error):
                print("Failed to load map: \(error)")
            }
        }
    }

    private func checkActiveActivities() {
        let activities = Activity<SHLWidgetAttributes>.activities.filter {
            $0.attributes.id == match.id
        }
        activityRunning = !activities.isEmpty
    }

    private func loadTeamColors() {
        match.awayTeam.getTeamColor { color in
            withAnimation { awayColor = color }
        }
        match.homeTeam.getTeamColor { color in
            withAnimation { homeColor = color }
        }
    }

    private func logAnalytics() {
        guard !hasLogged else { return }

        PostHogSDK.shared.capture(
            "match_view_interaction",
            properties: ["referrer": referrer],
            userProperties: ["match_id": match.id]
        )

        PostHogSDK.shared.capture("team_interaction", properties: ["team_code": match.homeTeam.code])
        PostHogSDK.shared.capture("team_interaction", properties: ["team_code": match.awayTeam.code])

        hasLogged = true
    }

    func startTimer() {
        print("Starting PBP update timer")
        pbpUpdateTimer?.invalidate()
        pbpUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { timer in
            guard isLive else {
                print("Disabling timer, match is not live")
                timer.invalidate()
                return
            }

            if let game = viewModel.liveGame, game.gameState == .played {
                print("Disabling timer, game has ended")
                timer.invalidate()
                return
            }

            Task {
                do {
                    try await viewModel.refreshPBP()
                } catch {
                    print("PBP refresh error: \(error)")
                }
            }
        }
    }
}

// MARK: - Previews

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
            homeTeam: TeamBasic(id: "team-1", name: "Brynäs", code: "BIF"),
            awayTeam: TeamBasic(id: "team-2", name: "Luleå Hockey", code: "LHF"),
            homeScore: 1,
            awayScore: 2,
            state: .ongoing,
            overtime: false,
            shootout: false,
            externalUUID: ""
        ),
        referrer: "PREVIEW"
    )
}
