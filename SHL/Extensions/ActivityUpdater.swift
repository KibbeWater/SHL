//
//  ActivityUpdater.swift
//
//
//  Created by KibbeWater on 3/27/24.
//

import PostHog
import HockeyKit
import Foundation
import ActivityKit
import UserNotifications

public class ActivityUpdater {
    @MainActor public static let shared: ActivityUpdater = ActivityUpdater()
    public var deviceUUID = UUID()
    
    func OverviewToState(_ overview: GameData.GameOverview) -> SHLWidgetAttributes.ContentState {
        return SHLWidgetAttributes.ContentState(homeScore: overview.homeGoals, awayScore: overview.awayGoals, period: .init(period: overview.time.period, periodEnd: (overview.time.periodEnd ?? Date()).ISO8601Format(), state: .intermission))
    }
    
    func OverviewToAttrib(_ overview: GameData.GameOverview) -> SHLWidgetAttributes {
        return SHLWidgetAttributes(id: overview.gameUuid, homeTeam: .init(name: overview.homeTeam.teamName, teamCode: overview.homeTeam.teamCode), awayTeam: .init(name: overview.awayTeam.teamName, teamCode: overview.awayTeam.teamCode))
    }
    
    func OverviewToAttrib(_ match: Game) -> SHLWidgetAttributes {
        return SHLWidgetAttributes(id: match.id, homeTeam: .init(name: match.homeTeam.name, teamCode: match.homeTeam.code), awayTeam: .init(name: match.awayTeam.name, teamCode: match.awayTeam.code))
    }
    
    @available(iOS 16.2, *)
    public func start(match: Game) throws {
        let attrib = OverviewToAttrib(match)
        let initState = SHLWidgetAttributes.ContentState(
            homeScore: 0,
            awayScore: 0,
            period: .init(
                period: 1,
                periodEnd: "",
                state: .intermission
            )
        )
        
        let activity = try Activity.request(
            attributes: attrib,
            content: .init(state: initState, staleDate: nil),
            pushType: .token
        )
        
        Task {
            let center = UNUserNotificationCenter.current()
            
            do {
                try await center.requestAuthorization(options: [.alert])
            } catch {
                
            }
        }
        
        Task {
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.reduce("") {
                    $0 + String(format: "%02x", $1)
                }
                
                
#if DEBUG
      print("Development Tokens: \(pushTokenString)")
#endif
                
                // Send the push token
                updatePushToken(match.id, token: pushTokenString)
            }
        }
    }
    
    @available(iOS 16.2, *)
    public func start(match: GameData.GameOverview) throws {
        let attrib = OverviewToAttrib(match)
        let initState = OverviewToState(match)
        
        let activity = try Activity.request(
            attributes: attrib,
            content: .init(state: initState, staleDate: nil),
            pushType: .token
        )
        
        Task {
            let center = UNUserNotificationCenter.current()
            
            do {
                try await center.requestAuthorization(options: [.alert])
            } catch {
                // Handle errors that may occur during requestAuthorization.
            }
        }
        
        Task {
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.reduce("") {
                    $0 + String(format: "%02x", $1)
                }
                
#if DEBUG
      print("Development Tokens: \(pushTokenString)")
#endif
                
                // Send the push token
                updatePushToken(match.gameUuid, token: pushTokenString)
            }
        }
    }
    
    func updatePushToken(_ matchUUID: String, token: String) {
        var json: [String: Any] = ["deviceUUID": deviceUUID.uuidString,
                                   "token": token,
                                   "matchId": matchUUID]
        
        #if DEBUG
        json["environment"] = "development"
        #endif

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let url = URL(string: "https://shl.lrlnet.se/api/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }

        task.resume()
    }
}
