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
    @Environment(\.hockeyAPI) var hockeyApi: HockeyAPI
    
    @ObservedObject private var settings = Settings.shared
    
    @State private var selectedTeam: String? = nil
    @State private var teams: [SiteTeam] = []
    @State private var teamsLoaded: Bool = false
    
    @CloudStorage(key: "preferredTeam", default: "")
    private var _preferredTeam: String
    
    func loadTeams() {
        Task {
            if let newTeams = try? await hockeyApi.team.getTeams() {
                teams = newTeams.sorted(by: { ($0.teamNames.long) ?? "" < ($1.teamNames.long) ?? "" })
                teamsLoaded = true
            }
        }
    }
    
    var body: some View {
        List {
            Section("General") {
                if teamsLoaded {
                    Picker("Preferred Team", selection: $_preferredTeam) {
                        Text("None")
                            .tag("")
                        ForEach(teams.filter({ !$0.id.isEmpty })) { team in
                            HStack {
                                Text(team.teamNames.long ?? "")
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
                    hockeyApi.resetCache()
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
