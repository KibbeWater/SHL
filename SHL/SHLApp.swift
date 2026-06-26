//
//  LHFApp.swift
//  LHF
//
//  Created by user242911 on 12/30/23.
//

import SwiftUI

@main
struct LHFApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Analytics.start()
        Analytics.track(.appOpened(source: "cold_start"))
    }

    var body: some Scene {
        WindowGroup {
            Root()
        }
    }
}
