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
    @State private var teams: [SiteTeam] = []
    @State private var teamsLoaded: Bool = false
    
    @CloudStorage(key: "preferredTeam", default: "")
    private var _preferredTeam: String
    
    func loadTeams() {
        Task {
            if let newTeams = try? await TeamAPI.shared.getTeams() {
                teams = newTeams.sorted(by: { ($0.names.long) ?? "" < ($1.names.long) ?? "" })
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
                                Text(team.names.long ?? "")
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
            }
            
            Section("Support Me") {
                /*Button("Leave a Tip") {
                    
                }*/
                
                Button("Rate App on the App Store") {
                    openURL(URL(string: "https://apps.apple.com/app/id\(SharedPreferenceKeys.appId)?action=write-review")!)
                }
            }
        }
        .onAppear {
            loadTeams()
        }
    }
}

#Preview {
    SettingsView()
}
