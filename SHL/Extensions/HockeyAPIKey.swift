//
//  HockeyAPIKey.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import HockeyKit
import SwiftUI

struct HockeyAPIKey: EnvironmentKey {
    static let defaultValue = HockeyAPI() // Provide a default instance if needed
}

extension EnvironmentValues {
    var hockeyAPI: HockeyAPI {
        get { self[HockeyAPIKey.self] }
        set { self[HockeyAPIKey.self] = newValue }
    }
}
