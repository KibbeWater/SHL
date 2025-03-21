//
//  LHFApp.swift
//  LHF
//
//  Created by user242911 on 12/30/23.
//

import SwiftUI
import HockeyKit
import PostHog

@main
struct LHFApp: App {
    var api: HockeyAPI = HockeyAPI()
    
    init() {
        let config = PostHogConfig(
            apiKey: SharedPreferenceKeys.POSTHOG_API_KEY,
            host: SharedPreferenceKeys.POSTHOG_HOST
        )
        
#if !DEBUG
        PostHogSDK.shared.setup(config)
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            Root()
                .environment(\.hockeyAPI, api)
        }
    }
}
