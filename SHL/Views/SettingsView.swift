//
//  SettingsView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 4/10/24.
//

import SwiftUI
import HockeyKit

struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    
    @State private var selectedTeam: String? = nil
    @State private var teams: [SiteTeam] = []
    @State private var teamsLoaded: Bool = false
    
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
                    Picker("Preferred Team", selection: settings.binding_preferredTeam()) {
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
        }
        .onAppear {
            loadTeams()
        }
    }
}

#Preview {
    SettingsView()
}
