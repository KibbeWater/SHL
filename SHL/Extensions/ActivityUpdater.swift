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

    private var pushToStartTokenTask: Task<Void, Never>?
    private var activityUpdatesTask: Task<Void, Never>?

    // MARK: - Push-to-Start Token Observation

    /// Start observing push-to-start token updates (iOS 17.2+)
    @available(iOS 17.2, *)
    public func startObservingPushToStartToken() {
        pushToStartTokenTask?.cancel()

        pushToStartTokenTask = Task {
            for await tokenData in Activity<SHLWidgetAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                #if DEBUG
                print("Push-to-start token: \(token)")
                #endif
                await registerPushToStartToken(token)
            }
        }

        // Also start observing activity updates to get update tokens for remotely-started activities
        startObservingActivityUpdates()
    }

    /// Stop observing push-to-start token updates
    public func stopObservingPushToStartToken() {
        pushToStartTokenTask?.cancel()
        pushToStartTokenTask = nil

        activityUpdatesTask?.cancel()
        activityUpdatesTask = nil
    }

    /// Register push-to-start token with backend
    private func registerPushToStartToken(_ token: String) async {
        guard settings.userManagementEnabled else {
            #if DEBUG
            print("Push-to-start: User management not enabled, skipping token registration")
            #endif
            return
        }

        guard settings.notificationSettings.autoStartLiveActivity else {
            #if DEBUG
            print("Push-to-start: Auto-start live activity disabled, skipping token registration")
            #endif
            return
        }

        #if DEBUG
        print("""

        ========== PUSH-TO-START TOKEN REGISTRATION ==========
        Token Type: pushToStart
        Token: \(token.prefix(20))...
        Device ID: \(keychain.getDeviceId())
        Primary Team Code: \(settings.getPrimaryTeamCode() ?? "nil")
        Auto-Start Enabled: \(settings.notificationSettings.autoStartLiveActivity)
        ======================================================

        """)
        #endif

        #if DEBUG
        print("🌐 Calling API: POST /push-tokens/register (push_to_start)")
        #endif

        do {
            let response = try await SHLAPIClient.shared.registerPushToken(
                token: token,
                type: "push_to_start",
                deviceId: keychain.getDeviceId(),
                teamCode: settings.getPrimaryTeamCode()
            )
            #if DEBUG
            print("✅ Successfully registered push-to-start token: \(response)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to register push-to-start token: \(error)")
            #endif
        }
    }

    // MARK: - Activity Updates Observation

    /// Start observing ALL activity updates (including remotely started ones) (iOS 17.2+)
    @available(iOS 17.2, *)
    public func startObservingActivityUpdates() {
        activityUpdatesTask?.cancel()

        activityUpdatesTask = Task {
            // Observe for new activities being created (locally or remotely)
            for await activity in Activity<SHLWidgetAttributes>.activityUpdates {
                #if DEBUG
                print("📱 Activity detected: \(activity.id) - observing push token updates")
                #endif

                // Start observing this activity's push token updates
                observePushTokenUpdates(for: activity)
            }
        }
    }

    /// Observe push token updates for a specific activity
    @available(iOS 16.2, *)
    private func observePushTokenUpdates(for activity: Activity<SHLWidgetAttributes>) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()

                #if DEBUG
                print("""

                ========== LIVE ACTIVITY UPDATE TOKEN ==========
                Activity ID: \(activity.id)
                Match ID: \(activity.attributes.id)
                Token: \(token.prefix(20))...
                ================================================

                """)
                #endif

                // Send update token to server
                updatePushToken(activity.attributes.id, token: token)
            }
        }
    }

    // MARK: - Activity Conversion Helpers

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

        // Just create the activity - token observation is handled centrally by startObservingActivityUpdates()
        let _ = try Activity.request(
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
    }
    
    func updatePushToken(_ matchUUID: String, token: String) {
        // Use authenticated API if user management is enabled
        if settings.userManagementEnabled {
            Task {
                #if DEBUG
                print("""

                ========== LIVE ACTIVITY TOKEN REGISTRATION ==========
                Token Type: liveActivity
                Match UUID: \(matchUUID)
                Token: \(token.prefix(20))...
                Device ID: \(keychain.getDeviceId())
                Using: Authenticated API
                ======================================================

                """)
                #endif

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
