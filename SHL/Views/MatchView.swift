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
    @Environment(\.scenePhase) private var scenePhase

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
    @State private var showNotificationReminder = false
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

    private var isCancelled: Bool { currentMatch.isCancelled }

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

                    if (hasStarted || isLive) && !isCancelled {
                        tabPicker
                    }

                    contentSection
                }
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
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
            trackMatchViewInteraction()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await viewModel.refresh(hard: true)
                }
                startTimer()
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: homeScore)
        .sensoryFeedback(.impact(weight: .heavy), trigger: awayScore)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.success, trigger: activityRunning)
        .sheet(isPresented: $showNotificationReminder) {
            NotificationReminderSheet(
                onEnable: {
                    Task {
                        if !Settings.shared.userManagementEnabled {
                            Settings.shared.userManagementEnabled = true
                        }
                        await PushNotificationManager.shared.requestPermissionsAndRegister()
                    }
                    Settings.shared.markNotificationReminderSeen()
                    showNotificationReminder = false
                },
                onSkip: {
                    Settings.shared.markNotificationReminderSeen()
                    showNotificationReminder = false
                }
            )
        }
    }

    // MARK: - Notification Reminder

    private func trackMatchViewInteraction() {
        Settings.shared.incrementMatchViewCount()

        Task {
            let status = await PushNotificationManager.shared.checkNotificationPermission()
            await MainActor.run {
                if Settings.shared.shouldShowNotificationReminder() &&
                   (status == .notDetermined || status == .denied) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showNotificationReminder = true
                    }
                }
            }
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

            // Dark scrim to guarantee white-text contrast against bright team colors
            // (e.g. yellow/light-blue teams would otherwise fail WCAG).
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.55), location: 0),
                    .init(color: .black.opacity(0.4), location: 0.25),
                    .init(color: .black.opacity(0.15), location: 0.55),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .center
            )

            LinearGradient(
                colors: [.clear, Color(uiColor: .systemBackground)],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.5), value: homeColor)
        .animation(.smooth(duration: 0.5), value: awayColor)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 18) {
            if let liveGame = viewModel.liveGame,
               liveGame.gameState == .ongoing || liveGame.gameState == .paused {
                liveHeaderSection(liveGame)
            } else {
                standardHeaderSection
            }
        }
        .padding(.top, 16)
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    // MARK: - Standard Header

    private var standardHeaderSection: some View {
        Group {
            if isCancelled {
                cancelledBadge
            } else if let liveGame = viewModel.liveGame {
                gameStatusBadge(liveGame)
            } else if match.played {
                finalBadge
            }

            HStack(alignment: .center, spacing: 16) {
                teamLogo(
                    code: currentMatch.homeTeam.code,
                    team: viewModel.home
                )

                Spacer()

                scoreCenterView

                Spacer()

                teamLogo(
                    code: currentMatch.awayTeam.code,
                    team: viewModel.away
                )
            }
            .padding(.horizontal, 24)

            if !hasStarted && viewModel.liveGame == nil {
                countdownBadge
            }

            headerMetadata
        }
    }

    // MARK: - Live Header

    private func liveHeaderSection(_ liveGame: LiveMatch) -> some View {
        Group {
            liveIndicatorBadge(liveGame)

            HStack(alignment: .center, spacing: 16) {
                liveTeamColumn(
                    code: currentMatch.homeTeam.code,
                    team: viewModel.home,
                    score: homeScore,
                    isWinning: homeScore >= awayScore
                )

                Spacer()

                liveCenterTimer(liveGame)

                Spacer()

                liveTeamColumn(
                    code: currentMatch.awayTeam.code,
                    team: viewModel.away,
                    score: awayScore,
                    isWinning: awayScore >= homeScore
                )
            }
            .padding(.horizontal, 24)

            headerMetadata
        }
    }

    @ViewBuilder
    private func liveIndicatorBadge(_ liveGame: LiveMatch) -> some View {
        if liveGame.gameState == .ongoing {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse.byLayer, options: .repeating)

                Text("LIVE")
                    .font(.caption.weight(.heavy))

                Text("•")
                    .foregroundStyle(.white.opacity(0.4))

                Text("P\(liveGame.period)")
                    .font(.caption.weight(.bold))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(.red.opacity(0.4))
                    .background(.ultraThinMaterial, in: .capsule)
            }
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
        } else {
            HStack(spacing: 6) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 9))
                Text("BREAK")
                    .font(.caption.weight(.bold))

                Text("•")
                    .foregroundStyle(.white.opacity(0.4))

                Text("P\(liveGame.period)")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: .capsule)
        }
    }

    private func liveTeamColumn(code: String, team: Team?, score: Int, isWinning: Bool) -> some View {
        Group {
            if let team = team {
                NavigationLink {
                    TeamView(team: team)
                } label: {
                    liveTeamColumnContent(code: code, score: score, isWinning: isWinning)
                }
                .buttonStyle(.scalePress)
            } else {
                liveTeamColumnContent(code: code, score: score, isWinning: isWinning)
            }
        }
    }

    private func liveTeamColumnContent(code: String, score: Int, isWinning: Bool) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(teamCode: code, size: .extraLarge)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            Text(code)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))

            Text("\(score)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .fontWidth(.compressed)
                .foregroundStyle(isWinning ? .white : .white.opacity(0.5))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(score)))
                .animation(.snappy, value: score)
        }
    }

    @ViewBuilder
    private func liveCenterTimer(_ liveGame: LiveMatch) -> some View {
        if liveGame.gameState == .ongoing {
            Text(
                timerInterval: Date.now...max(Date.now, liveGame.periodEnd),
                pauseTime: Date.now,
                countsDown: true,
                showsHours: false
            )
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
        } else {
            VStack(spacing: 4) {
                Image(systemName: "pause.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Break")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func teamLogo(code: String, team: Team?) -> some View {
        Group {
            if let team = team {
                NavigationLink {
                    TeamView(team: team)
                } label: {
                    teamLogoContent(code: code)
                }
                .buttonStyle(.scalePress)
            } else {
                teamLogoContent(code: code)
            }
        }
    }

    private func teamLogoContent(code: String) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(teamCode: code, size: .extraLarge)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            Text(code)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var scoreCenterView: some View {
        VStack(spacing: 4) {
            if isCancelled {
                VStack(spacing: 4) {
                    Text("—")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Not played")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else if hasStarted {
                HStack(spacing: 12) {
                    Text("\(homeScore)")
                        .foregroundStyle(homeScore >= awayScore ? .white : .white.opacity(0.5))
                        .contentTransition(.numericText(value: Double(homeScore)))

                    Text("–")
                        .foregroundStyle(.white.opacity(0.4))

                    Text("\(awayScore)")
                        .foregroundStyle(awayScore >= homeScore ? .white : .white.opacity(0.5))
                        .contentTransition(.numericText(value: Double(awayScore)))
                }
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .fontWidth(.compressed)
                .monospacedDigit()
                .animation(.snappy, value: homeScore)
                .animation(.snappy, value: awayScore)
            } else {
                // Future game - show date and time prominently
                VStack(spacing: 6) {
                    if match.isToday {
                        Text("Today")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Text(match.date.formatted(.dateTime.weekday(.wide)))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .kerning(1.5)

                        Text(match.formatDate())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text(match.date.formatted(date: .omitted, time: .shortened))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .monospacedDigit()
                }
            }
        }
    }

    private func gameStatusBadge(_ liveGame: LiveMatch) -> some View {
        HStack(spacing: 6) {
            if liveGame.gameState == .ongoing {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text(statusText(for: liveGame))
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
    }

    private func statusText(for liveGame: LiveMatch) -> String {
        switch liveGame.gameState {
        case .ongoing:
            return "LIVE • P\(liveGame.period)"
        case .paused:
            return "BREAK"
        case .played:
            return "FINAL"
        case .cancelled:
            return "CANCELLED"
        case .scheduled:
            return "SOON"
        }
    }

    private var countdownBadge: some View {
        let timeUntilGame = match.date.timeIntervalSince(Date.now)
        let days = Int(timeUntilGame / 86400)
        let hours = Int((timeUntilGame.truncatingRemainder(dividingBy: 86400)) / 3600)

        return HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.caption)
                .symbolRenderingMode(.hierarchical)

            if days > 0 {
                Text("\(days)d \(hours)h until puck drop")
                    .font(.caption.weight(.semibold))
            } else if hours > 0 {
                Text("\(hours)h until puck drop")
                    .font(.caption.weight(.semibold))
            } else {
                Text("Starting soon")
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
    }

    private var finalBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "flag.checkered")
                .font(.caption)
            Text("FINAL")
                .font(.caption.weight(.bold))
                .kerning(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
    }

    private var cancelledBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
            Text("CANCELLED")
                .font(.caption.weight(.bold))
                .kerning(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
    }

    private var cancelledNoticeCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
            Text("Match Cancelled")
                .font(.headline)
            Text("This game was cancelled and will not be played.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private var dateLabel: some View {
        Label {
            Text("\(match.formatDate()) • \(match.formatTime())")
        } icon: {
            Image(systemName: "calendar")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white.opacity(0.95))
    }

    @ViewBuilder
    private var venueLabel: some View {
        if let venue = match.venue {
            Label(venue, systemImage: "mappin.and.ellipse")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))
        }
    }

    private var headerMetadata: some View {
        VStack(spacing: 4) {
            dateLabel
            venueLabel
        }
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 1)
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
                .transition(.opacity.combined(with: .move(edge: .leading)))
        case .pbp:
            pbpContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    // MARK: - Summary Content

    private var summaryContent: some View {
        VStack(spacing: 16) {
            if isCancelled {
                cancelledNoticeCard
            } else {
                if isLive || (!match.concluded && hasStarted) {
                    liveActivityCard
                }

                if hasStarted {
                    statsCard
                }

                if !hasStarted {
                    upcomingGameInfoCard
                }
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
                    .font(.headline.weight(.semibold))
                Spacer()
            }

            VStack(spacing: 12) {
                infoRow(icon: "calendar", title: "Date & Time", value: "\(match.formatDate()), \(match.formatTime())")

                if let venue = match.venue {
                    Divider()
                    infoRow(icon: "mappin.and.ellipse", title: "Venue", value: venue)
                }

                Divider()
                infoRow(
                    icon: "sportscourt.fill",
                    title: "Matchup",
                    value: "\(currentMatch.homeTeam.name) vs \(currentMatch.awayTeam.name)"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }

            Spacer()
        }
    }

    private var liveActivityCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: activityRunning ? "bell.badge.fill" : "bell.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activityRunning ? "Following Game" : "Follow Live")
                    .font(.headline.weight(.semibold))

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
            .tint(activityRunning ? .red : .accentColor)
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Game Stats", systemImage: "chart.bar.xaxis")
                    .font(.headline.weight(.bold))
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
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private var venueMapCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Venue", systemImage: "map.fill")
                    .font(.headline.weight(.bold))
                Spacer()

                Button {
                    openInMaps()
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(.caption.weight(.semibold))
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
                    ZStack {
                        Color(uiColor: .tertiarySystemFill)
                        ProgressView()
                    }
                    .onAppear {
                        loadMap(size: geo.size)
                    }
                }
            }
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 12, style: .continuous))
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
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
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
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
            userProperties: ["activity_id": KeychainManager.shared.getDeviceId()]
        )

        if let liveMatch = viewModel.liveGame {
            try ActivityUpdater.shared.start(match: liveMatch)
            activityRunning = true
        }
    }

    private func stopLiveActivity() {
        var activities = Activity<SHLWidgetAttributes>.activities
        activities = activities.filter { $0.attributes.internalId == match.id }

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
            $0.attributes.internalId == match.id
        }
        activityRunning = !activities.isEmpty
    }

    private func loadTeamColors() {
        match.awayTeam.getTeamColor { color in
            withAnimation(.smooth(duration: 0.5)) { awayColor = color }
        }
        match.homeTeam.getTeamColor { color in
            withAnimation(.smooth(duration: 0.5)) { homeColor = color }
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
        if isCancelled { return }
        print("Starting PBP update timer")
        pbpUpdateTimer?.invalidate()
        pbpUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { timer in
            guard isLive else {
                print("Disabling timer, match is not live")
                timer.invalidate()
                return
            }

            if let game = viewModel.liveGame, game.gameState == .played || game.gameState == .cancelled {
                print("Disabling timer, game concluded")
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
    NavigationStack { MatchView(Match.fakeData(), referrer: "PREVIEW") }
}

#Preview("Upcoming") {
    NavigationStack {
        MatchView(
            Match(
                id: "upcoming-preview",
                date: Date().addingTimeInterval(3600 * 26),
                venue: "Avicii Arena",
                homeTeam: TeamBasic(id: "team-1", name: "Djurgårdens IF", code: "DIF"),
                awayTeam: TeamBasic(id: "team-2", name: "Frölunda HC", code: "FHC"),
                homeScore: 0,
                awayScore: 0,
                state: .scheduled,
                overtime: false,
                shootout: false,
                externalUUID: ""
            ),
            referrer: "PREVIEW"
        )
    }
}

#Preview("Cancelled") {
    NavigationStack {
        MatchView(
            Match(
                id: "cancelled-preview",
                date: Date().addingTimeInterval(-3600),
                venue: "Be-Ge Hockey Center",
                homeTeam: TeamBasic(id: "team-1", name: "IK Oskarshamn", code: "IKO"),
                awayTeam: TeamBasic(id: "team-2", name: "Frölunda HC", code: "FHC"),
                homeScore: 0,
                awayScore: 0,
                state: .cancelled,
                overtime: false,
                shootout: false,
                externalUUID: ""
            ),
            referrer: "PREVIEW"
        )
    }
}

#Preview("Live") {
    NavigationStack {
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
}

#Preview("Dark") {
    NavigationStack { MatchView(Match.fakeData(), referrer: "PREVIEW") }
        .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    NavigationStack { MatchView(Match.fakeData(), referrer: "PREVIEW") }
}
