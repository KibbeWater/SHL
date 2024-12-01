//
//  LHFApp.swift
//  LHF
//
//  Created by user242911 on 12/30/23.
//

import SwiftUI
import HockeyKit

@main
struct LHFApp: App {
    var api: HockeyAPI = HockeyAPI()
    
    var body: some Scene {
        WindowGroup {
            Root()
                .environment(\.hockeyAPI, api)
        }
    }
}
