//
//  SettingsView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 4/10/24.
//

import SwiftUI
import HockeyKit

struct SettingsView: View {
    @Environment(\.openURL) var openURL
    
    @ObservedObject private var settings = Settings.shared
    
    @State private var selectedTeam: String? = nil
    @State private var teams: [Team] = []
    @State private var teamsLoaded: Bool = false

    private let api = SHLAPIClient.shared
    
    func loadTeams() {
        Task {
            if let newTeams = try? await api.getTeams() {
                teams = newTeams.sorted(by: { ($0.name) < ($1.name) })
                teamsLoaded = true
            }
        }
    }
    
    var body: some View {
        List {
            Section("General") {
                if teamsLoaded {
                    Picker("Preferred Team", selection: settings.binding_preferredTeam()) {
                        Text("None")
                            .tag("")
                        ForEach(teams.filter({ !$0.id.isEmpty })) { team in
                            HStack {
                                Text(team.name)
                                /*Image("Team/\(team.names.code.uppercased())")
                                    .resizable()
                                    .frame(width: 16, height: 16)*/
                            }
                            .tag(team.id)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    HStack {
                        Text("Preferred Team")
                        Spacer()
                        ProgressView()
                    }
                }
                
#if DEBUG
                Button("Reset Cache", role: .destructive) {
                }
#endif
            }
            
            Section("Support Me") {
                /*Button("Leave a Tip") {
                    
                }*/
                
                Button("Rate App on the App Store") {
                    openURL(URL(string: "https://apps.apple.com/app/id\(SharedPreferenceKeys.appId)?action=write-review")!)
                }
            }
            
            Section("App Info") {
                let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
                let version = nsObject as! String
                
#if DEBUG
                Text("Build Version: \(version) (DEBUG)")
#else
                Text("Build Version: \(version)")
#endif
            }
        }
        .onAppear {
            loadTeams()
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.hockeyAPI, HockeyAPI())
}
