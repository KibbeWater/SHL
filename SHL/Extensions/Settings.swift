//
//  Settings.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 5/10/24.
//

import SwiftUI

public enum SharedPreferenceKeys {
    static let appId = "6479990812"
    static let groupIdentifier: String = "group.kibbewater.shl"
    
    static let POSTHOG_API_KEY = "phc_lPkiCHQ8ZL15IfkCzHRzMaPTv1teimNnfNGrNmpRiPa"
    static let POSTHOG_HOST = "https://eu.i.posthog.com"
}

class Settings: ObservableObject {
    public static let shared = Settings()
    
    @CloudStorage(key: "preferredTeam", default: "")
    private var _preferredTeam: String
    
    public func getPreferredTeam() -> String? {
        let team = _preferredTeam.isEmpty ? nil : _preferredTeam
        return team
    }
    
    public func binding_preferredTeam() -> Binding<String> {
        return $_preferredTeam
    }
}
