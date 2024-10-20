//
//  Settings.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 5/10/24.
//

import SwiftUI

class Settings: ObservableObject {
    public static let shared = Settings()
    public static let appId = "6479990812"
    
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
