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
    @State private var previousMatches: [Game] = []
    @State private var todayMatches: [Game] = []
    @State private var upcomingMatches: [Game] = []
    
    @State private var matchListeners: [GameUpdater] = []
    
    @State private var scheduledNotifs: [String: Bool] = [:]

    // When matchInfo changes, re-filter the matches
    private func filterMatches() {
        let now = Date()
        let calendar = Calendar.current
        previousMatches = matchInfo.latestMatches.filter { $0.date < calendar.startOfDay(for: now) }
        todayMatches = matchInfo.latestMatches.filter { calendar.isDateInToday($0.date) }
        upcomingMatches = matchInfo.latestMatches.filter { calendar.startOfDay(for: $0.date) >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! }
        
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
            self.filterMatches()
            Task {
                await refreshActiveReminders()
            }
        }
        .onChange(of: matchInfo.latestMatches) { _ in
            Task {
                await refreshActiveReminders()
            }
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
    
    private func matchesScrollView(for matches: [Game]) -> some View {
        VStack {
            ScrollView {
                ForEach(matches, id: \.id) { match in
                    if match.date < Date.now {
                        NavigationLink {
                            MatchView(match: match)
                        } label: {
                            if #available(iOS 17.2, *) {
                                MatchOverview(game: match, liveGame: getLiveMatch(gameId: match.id))
                                    .id("pm-\(match.id)")
                                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                                    .contextMenu {
                                        Button("Start Activity", systemImage: "plus") {
                                            if let live = getLiveMatch(gameId: match.id) {
                                                do {
                                                    try ActivityUpdater.shared.start(match: live)
                                                } catch {
                                                    print("Failed to start activity")
                                                }
                                            }
                                        }
                                        
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
                                .padding(.horizontal)
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
                        }
                        .buttonStyle(PlainButtonStyle())
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
