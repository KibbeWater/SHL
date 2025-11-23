//
//  ActivityUpdater.swift
//
//
//  Created by KibbeWater on 3/27/24.
//

import Foundation
import ActivityKit
import UserNotifications

public class ActivityUpdater {
    @MainActor public static let shared: ActivityUpdater = ActivityUpdater()
    public var deviceUUID = UUID()

    private let settings = Settings.shared
    private let keychain = KeychainManager.shared

    func OverviewToAttrib(_ liveMatch: LiveMatch) -> SHLWidgetAttributes {
        return SHLWidgetAttributes(id: liveMatch.externalId, homeTeam: .init(name: liveMatch.homeTeam.name, teamCode: liveMatch.homeTeam.code), awayTeam: .init(name: liveMatch.awayTeam.name, teamCode: liveMatch.awayTeam.code))
    }

    func OverviewToState(_ liveMatch: LiveMatch) -> SHLWidgetAttributes.ContentState {
        return SHLWidgetAttributes.ContentState(homeScore: liveMatch.homeScore, awayScore: liveMatch.awayScore, period: .init(period: liveMatch.period, periodEnd: liveMatch.periodEnd.ISO8601Format(), state: .intermission))
    }

    @available(iOS 16.2, *)
    public func start(match: LiveMatch) throws {
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
                updatePushToken(match.externalId, token: pushTokenString)
            }
        }
    }
    
    func updatePushToken(_ matchUUID: String, token: String) {
        // Use authenticated API if user management is enabled
        if settings.userManagementEnabled {
            Task {
                do {
                    let response = try await SHLAPIClient.shared.registerLiveActivityToken(
                        matchUUID: matchUUID,
                        token: token
                    )
                    print("✅ Successfully registered live activity token (authenticated): \(response)")
                } catch {
                    print("❌ Failed to register live activity token (authenticated): \(error)")
                    // Fallback to unauthenticated if registration fails
                    fallbackUpdatePushToken(matchUUID, token: token)
                }
            }
        } else {
            // Use legacy unauthenticated endpoint
            fallbackUpdatePushToken(matchUUID, token: token)
        }
    }

    private func fallbackUpdatePushToken(_ matchUUID: String, token: String) {
        var json: [String: Any] = ["token": token,
                                   "deviceUUID": deviceUUID.uuidString]

        #if DEBUG
        json["environment"] = "development"
        #endif

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let url = URL(string: "https://api.lrlnet.se/api/v1/live/\(matchUUID)")!
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
                print("✅ Successfully registered live activity token (legacy): \(responseJSON)")
            }
        }

        task.resume()
    }
}
