//
//  LHF_DemoApp.swift
//  LHF Demo
//
//  Created by KibbeWater on 3/25/24.
//

import SwiftUI
import HockeyKit

@main
struct LHF_DemoApp: App {
    var api = HockeyAPI()
    
    var body: some Scene {
        WindowGroup {
            Root()
                .environmentObject(api)
        }
    }
}
