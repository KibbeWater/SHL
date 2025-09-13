//
//  LiveContext.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 21/4/25.
//

import SwiftUI
import PostHog
import HockeyKit

struct LiveContext: View {
    var live: GameData.GameOverview
    
    var body: some View {
        Button("Start Activity", systemImage: "plus") {
            do {
                PostHogSDK.shared.capture(
                    "started_live_activity",
                    properties: [
                        "join_type": "match_list_ctx"
                    ],
                    userProperties: [
                        "activity_id": ActivityUpdater.shared.deviceUUID.uuidString
                    ]
                )
                try ActivityUpdater.shared.start(match: live)
            } catch {
                print("Failed to start activity")
            }
        }
    }
}
