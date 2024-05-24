import SwiftUI
import ActivityKit
import HockeyKit

private enum Tabs: String, CaseIterable {
    case previous = "Previous"
    case today = "Today"
    case upcoming = "Upcoming"
}

struct MatchListView: View {
    @EnvironmentObject var matchInfo: MatchInfo
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab: Tabs = .today
    @State private var latestMatches: SeasonSchedule? = nil
    @State private var previousMatches: [Game] = []
    @State private var todayMatches: [Game] = []
    @State private var upcomingMatches: [Game] = []
    
    @State private var matchListeners: [GameUpdater] = []
    
    @State private var scheduledNotifs: [String: Bool] = [:]
    
    @State private var openDates: [String: Bool] = [:]

    // When matchInfo changes, re-filter the matches
    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current
        previousMatches = latestMatches?.gameInfo.filter({ $0.startDateTime < calendar.startOfDay(for: now) }).map { $0.toGame() } ?? []
        todayMatches = latestMatches?.gameInfo.filter({ calendar.isDateInToday($0.startDateTime) }).map { $0.toGame() } ?? []
        upcomingMatches = latestMatches?.gameInfo.filter({ calendar.startOfDay(for: $0.startDateTime) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }).map { $0.toGame() } ?? []
        
        matchListeners.removeAll(where: { _listener in
            return !todayMatches.contains(where: { $0.id == _listener.gameId })
        })
        let missingListeners = todayMatches.filter({ _match in
            return !matchListeners.contains(where: { $0.gameId == _match.id })
        })
        
        matchListeners.append(contentsOf: missingListeners.map({ _match in
            return GameUpdater(gameId: _match.id)
        }))
    }
    
    private func getLiveMatch(gameId: String) -> GameOverview? {
        return matchListeners.first(where: { $0.gameId == gameId })?.game
    }
    
    private func refreshActiveReminders() async {
        let notifCenter = UNUserNotificationCenter.current()
        var notifSnapshot = scheduledNotifs
        (await notifCenter.pendingNotificationRequests()).forEach { _notif in
            if matchInfo.latestMatches.contains(where: { $0.id == _notif.identifier }) {
                notifSnapshot[_notif.identifier] = true
            } else if notifSnapshot[_notif.identifier] == true {
                notifSnapshot[_notif.identifier] = false
            }
        }
        
        scheduledNotifs = notifSnapshot
    }
    
    var body: some View {
        VStack {
            tabSelectionView
            
            TabView(selection: $selectedTab) {
                matchesScrollView(for: previousMatches)
                    .id(Tabs.previous)
                    .tag(Tabs.previous)
                
                matchesScrollView(for: todayMatches)
                    .id(Tabs.today)
                    .tag(Tabs.today)
                
                matchesScrollView(for: upcomingMatches)
                    .id(Tabs.upcoming)
                    .tag(Tabs.upcoming)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
        .onAppear {
            Task {
                print("Fetching season")
                if let season = try? await matchInfo.getCurrentSeason() {
                    print("Current season found")
                    print(season)
                    latestMatches = try? await matchInfo.getSchedule(season)
                }
                await refreshActiveReminders()
            }
        }
        .onChange(of: latestMatches) { _ in
            Task {
                await refreshActiveReminders()
            }
            filterMatches()
        }
        .onChange(of: scenePhase) { _ in
            guard scenePhase == .active else {
                return
            }
            
            matchListeners.forEach { listener in
                listener.refreshPoller()
            }
            
            Task {
                do {
                    try await matchInfo.getLatest()
                } catch {
                    print("Unable to refresh")
                }
            }
        }
    }
    
    private var tabSelectionView: some View {
        HStack {
            Spacer()
            ForEach(Tabs.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }, label: {
                    Text(tab.rawValue)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                })
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
    }
    
    private func refresh() async {
        matchListeners.forEach({ $0.refreshPoller() })
        do {
            try await matchInfo.getLatest()
        } catch {
            print("Unable to refresh matches")
        }
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
            if success {
                print("Authorization granted")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func removeMatchNotification(match: Game) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [match.id])
        await refreshActiveReminders()
        print(scheduledNotifs)
    }
    
    private func scheduleMatchNotification(match: Game) async {
        requestNotificationAuthorization()
        
        let content = UNMutableNotificationContent()
        content.title = "Match Starting"
        content.body = "The match between \(match.homeTeam.name) and \(match.awayTeam.name) is about to begin in 5 minutes"
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        let remindDate: Date = calendar.date(byAdding: .minute, value: -5, to: match.date)!
        let dateComponents: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: match.id, content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        do {
            if (await notificationCenter.pendingNotificationRequests()).first(where: { $0.identifier == match.id }) != nil {
                await refreshActiveReminders()
                return
            }
            
            try await notificationCenter.add(request)
            await refreshActiveReminders()
        } catch let _err {
            print(_err)
        }
    }
    
    private func matchItem(_ match: Game) -> some View {
        HStack {
            if match.date < Date.now {
                NavigationLink {
                    MatchView(match: match)
                } label: {
                    if #available(iOS 17.2, *) {
                        MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                            .id("pm-\(match.id)")
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .contextMenu {
                                #if !APPCLIP
                                Button("Start Activity", systemImage: "plus") {
                                    if let live = getLiveMatch(gameId: match.id) {
                                        do {
                                            try ActivityUpdater.shared.start(match: live)
                                        } catch {
                                            print("Failed to start activity")
                                        }
                                    }
                                }
                                #endif
                                
                                #if DEBUG
                                Button("Debug Activity") {
                                    try? ActivityUpdater.shared.start(match: GameOverview.generateFake())
                                }
                                #endif
                            }
                            .padding(.horizontal)
                    } else {
                        MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                            .id("pm-\(match.id)")
                            .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            .padding(.horizontal)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                let isNotifScheduled = scheduledNotifs[match.id] == true
                NavigationLink {
                    MatchView(match: match)
                } label: {
                    MatchOverview(game: match)
                        .id("pm-\(match.id)")
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        .contextMenu {
                            Button(isNotifScheduled ? "Remove Reminder" : "Remind Me", systemImage: isNotifScheduled ? "bell.slash" :  "bell.and.waves.left.and.right") {
                                Task {
                                    guard isNotifScheduled else {
                                        await scheduleMatchNotification(match: match)
                                        return
                                    }
                                    
                                    await removeMatchNotification(match: match)
                                }
                            }
                        }
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func getDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    private func getGroupDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Calendar.current.isDate(Date.now, equalTo: date, toGranularity: .year) 
            ? "EEEE, d MMM"
            : "EEEE, d MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    private func matchesScrollView(for matches: [Game]) -> some View {
        VStack {
            ScrollView {
                if matches.first?.date ?? Date.now > Date.now {
                    let matchGroups = matches.groupBy(keySelector: { getDate($0.date) })
                    ForEach(matchGroups.keys.sorted(), id: \.self) { key in
                        let matchList = matchGroups[key]!
                        let isFirst = matchGroups.keys.sorted().first == key
                        VStack {
                            HStack {
                                Text(getGroupDate(matchList.first?.date ?? Date.now))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.bold)
                                Spacer()
                                if !isFirst {
                                    Button(openDates[key] == true ? "Show less" : "Show more", systemImage: openDates[key] == true ? "chevron.up" : "chevron.down") {
                                        let isOpen = openDates[key] ?? false
                                        withAnimation {
                                            if isOpen {
                                                openDates[key] = false
                                            } else {
                                                openDates[key] = true
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            if openDates[key] == true || isFirst {
                                LazyVStack {
                                    ForEach(matchList, id: \.id) { match in
                                        matchItem(match)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                } else {
                    ForEach(matches, id: \.id) { match in
                        matchItem(match)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .center, content: {
            if (matches.isEmpty) {
                Text("No matches")
            }
        })
        .refreshable {
            await refresh()
        }
    }
}
