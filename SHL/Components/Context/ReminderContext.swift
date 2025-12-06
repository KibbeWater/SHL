//
//  ReminderContext.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 20/9/24.
//

import SwiftUI
import PostHog

struct ReminderContext: View {
    let game: Match

    @State private var isNotificationScheduled: Bool = false
    static private var activeReminders: [String:Bool] = [:]

    init(game: Match) {
        self.game = game
        reloadReminders()
    }

    static func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
            guard let _err = error else {
                return
            }
            print(_err.localizedDescription)
        }
    }
    
    private func removeMatchNotification(match: Match) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [match.id])
        await ReminderContext.refreshActiveReminders()
    }
    
    private func scheduleMatchNotification(match: Match) async {
        ReminderContext.requestNotificationAuthorization()
        
        let content = UNMutableNotificationContent()
        content.title = "Match Starting"
        content.body = "The match between \(match.homeTeam.name) and \(match.awayTeam.name) is about to begin in 5 minutes"
        content.sound = UNNotificationSound.default
        content.userInfo = ["matchId": match.id]
        
        let calendar = Calendar.current
        let remindDate: Date = calendar.date(byAdding: .minute, value: -5, to: match.date)!
        let dateComponents: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: match.id, content: content, trigger: trigger)
        
        PostHogSDK.shared.capture(
            "match_reminder_created",
            properties: [
                "match_id": match.id,
                "teams": [
                    match.homeTeam.code,
                    match.awayTeam.code
                ]
            ],
            userProperties: ["interested_teams_count": Settings.shared.getInterestedTeamIds().count]
        )
        
        let notificationCenter = UNUserNotificationCenter.current()
        do {
            if (await notificationCenter.pendingNotificationRequests()).first(where: { $0.identifier == match.id }) != nil {
                await ReminderContext.refreshActiveReminders()
                return
            }
            
            try await notificationCenter.add(request)
            await ReminderContext.refreshActiveReminders()
        } catch let _err {
            print(_err)
        }
    }
    
    static func refreshActiveReminders() async {
        let notifCenter = UNUserNotificationCenter.current()
        
        var snapshot: [String:Bool] = [:]
        (await notifCenter.pendingNotificationRequests()).forEach { _notif in
            snapshot[_notif.identifier] = true
        }
        
        activeReminders = snapshot
    }
    
    func reloadReminders() {
        isNotificationScheduled = ReminderContext.activeReminders[game.id] ?? false
    }

    var body: some View {
        Button(isNotificationScheduled ? "Remove Reminder" : "Remind Me", systemImage: isNotificationScheduled ? "bell.slash" :  "bell.and.waves.left.and.right") {
            Task {
                if isNotificationScheduled {
                    await removeMatchNotification(match: game)
                } else {
                    await scheduleMatchNotification(match: game)
                }
                
                isNotificationScheduled.toggle()
                await ReminderContext.refreshActiveReminders()
            }
        }
        .onAppear {
            reloadReminders()
        }
    }
}

#Preview {
    VStack {Color.red}
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            ReminderContext(game: Match.fakeData())
        }
}
