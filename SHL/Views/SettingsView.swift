//
//  SettingsView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 4/10/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) var openURL

    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var pushManager = PushNotificationManager.shared

    @State private var teams: [Team] = []
    @State private var teamsLoaded: Bool = false
    @State private var showDeleteAccountAlert = false
    @State private var showTeamSelectionSheet = false
    @State private var showFavoriteTeamPicker = false
    @State private var devices: [Device] = []
    @State private var isLoadingDevices = false
    @State private var showResetOnboardingAlert = false

    private let api = SHLAPIClient.shared
    
    func loadTeams() {
        Task {
            if let newTeams = try? await api.getTeams() {
                await MainActor.run {
                    teams = newTeams.sorted(by: { ($0.name) < ($1.name) })
                    teamsLoaded = true
                }

                // Populate cached interested teams from stored IDs
                let interestedIds = settings.getInterestedTeamIds()
                if !interestedIds.isEmpty {
                    let cachedTeams = interestedIds.compactMap { id in
                        newTeams.first(where: { $0.id == id }).map { team in
                            InterestedTeam(id: team.id, name: team.name, code: team.code, city: nil)
                        }
                    }
                    settings.cacheInterestedTeams(cachedTeams)
                }
            }
        }
    }

    func loadDevices() {
        isLoadingDevices = true
        Task {
            do {
                let response = try await api.getDevices()
                await MainActor.run {
                    devices = response.devices
                    isLoadingDevices = false
                }
            } catch {
                print("Failed to load devices: \(error)")
                await MainActor.run {
                    isLoadingDevices = false
                }
            }
        }
    }

    func deleteAccount() {
        Task {
            do {
                try await authManager.deleteAccount()
                // Account deleted successfully
            } catch {
                print("Failed to delete account: \(error)")
            }
        }
    }

    /// Look up the full Team (for logo/city) backing a stored interested-team id.
    private func fullTeam(_ id: String) -> Team? {
        teams.first { $0.id == id }
    }

    private var interestedTeamsEmptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.2.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No teams followed yet")
                .font(.subheadline.weight(.medium))
            Text("Add teams to get match alerts and a personalized home screen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .listRowSeparator(.hidden)
    }

    var body: some View {
        List {
            Section {
                if teamsLoaded {
                    let interestedTeams = settings.getInterestedTeams()
                    let favoriteTeam = settings.getFavoriteTeam()
                    let favoriteId = settings.getFavoriteTeamId()

                    if interestedTeams.isEmpty {
                        interestedTeamsEmptyState
                    } else {
                        // Favorite team (hero)
                        if let favoriteTeam {
                            FavoriteTeamRow(
                                name: favoriteTeam.name,
                                code: favoriteTeam.code,
                                city: favoriteTeam.city ?? fullTeam(favoriteTeam.id)?.city,
                                iconURL: fullTeam(favoriteTeam.id)?.iconURL
                            ) {
                                showFavoriteTeamPicker = true
                            }
                        }

                        // Other followed teams
                        ForEach(interestedTeams.filter { $0.id != favoriteId }) { team in
                            InterestedTeamRow(
                                name: team.name,
                                code: team.code,
                                iconURL: fullTeam(team.id)?.iconURL
                            )
                        }
                    }

                    Button {
                        showTeamSelectionSheet = true
                    } label: {
                        Label(interestedTeams.isEmpty ? "Select Teams" : "Edit Teams", systemImage: "person.2.fill")
                    }

                    if !interestedTeams.isEmpty && favoriteTeam == nil {
                        Button {
                            showFavoriteTeamPicker = true
                        } label: {
                            Label("Set Favorite Team", systemImage: "star")
                        }
                    }
                } else {
                    HStack {
                        Text("Loading teams…")
                        Spacer()
                        ProgressView()
                    }
                }
            } header: {
                Text("Interested Teams")
            } footer: {
                if let favoriteTeam = settings.getFavoriteTeam() {
                    Text("You'll receive notifications for your selected teams. \(favoriteTeam.name) matches will be prioritized on your home screen.")
                } else {
                    Text("You'll receive notifications for matches involving your selected teams.")
                }
            }


            // MARK: - Notifications

            Section {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell.badge")
                }
            } footer: {
                Text("Choose which teams notify you about game starts, goals, and final scores.")
            }

            // MARK: - Account Management

            Section("Account") {
                if authManager.isAuthenticated {
                    if let userId = authManager.currentUserId {
                        VStack(alignment: .leading) {
                            Text("User ID")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(userId)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    }

                    Button("View Devices") {
                        loadDevices()
                    }

                    Button("Delete Account", role: .destructive) {
                        showDeleteAccountAlert = true
                    }
                } else {
                    HStack {
                        Text("Setting up your account…")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and will remove all your data from our servers.")
            }

            // MARK: - Security Settings

            Section {
                Toggle("Sync Authentication Across Devices", isOn: settings.binding_keychainSyncEnabled())
                    .tint(.accentColor)
            } header: {
                Text("Security")
            } footer: {
                Text("When enabled, your login will sync to other devices signed into iCloud. This allows you to stay logged in across all your devices. You can disable this if you prefer to manage authentication separately on each device.")
            }

            // MARK: - Debug Tools Section

#if DEBUG
            Section("Debug Tools") {
                if authManager.isAuthenticated {
                    NavigationLink {
                        NotificationTestView()
                    } label: {
                        Label("Test Push Notifications", systemImage: "bell.badge.fill")
                    }
                }

                Button("Reset Onboarding") {
                    showResetOnboardingAlert = true
                }
            }
#endif

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
        .sheet(isPresented: $showTeamSelectionSheet) {
            TeamSelectionSheet(
                allTeams: teams,
                selectedTeamIds: settings.getInterestedTeamIds()
            ) { selectedIds in
                // Convert selected IDs to InterestedTeam objects
                let selectedTeams = selectedIds.compactMap { id in
                    teams.first(where: { $0.id == id }).map { team in
                        InterestedTeam(id: team.id, name: team.name, code: team.code, city: nil)
                    }
                }
                settings.setInterestedTeams(selectedTeams)
            }
        }
        .sheet(isPresented: $showFavoriteTeamPicker) {
            NavigationStack {
                List {
                    let interestedTeams = settings.getInterestedTeams()
                    let currentFavorite = settings.getFavoriteTeamId()

                    Section {
                        ForEach(interestedTeams) { team in
                            Button {
                                settings.setFavoriteTeamId(team.id)
                                showFavoriteTeamPicker = false
                            } label: {
                                HStack(spacing: 12) {
                                    TeamLogoView(teamCode: team.code, iconURL: fullTeam(team.id)?.iconURL, size: .custom(28))
                                        .frame(width: 30, height: 30)

                                    Text(team.name)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if currentFavorite == team.id {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                    } else {
                                        TeamCodeBadge(code: team.code)
                                    }
                                }
                            }
                        }

                        if currentFavorite != nil {
                            Button(role: .destructive) {
                                settings.setFavoriteTeamId(nil)
                                showFavoriteTeamPicker = false
                            } label: {
                                Label("Remove Favorite", systemImage: "star.slash")
                            }
                        }
                    } header: {
                        Text("Select Favorite Team")
                    } footer: {
                        Text("Your favorite team's matches will be prioritized on your home screen.")
                    }
                }
                .navigationTitle("Favorite Team")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showFavoriteTeamPicker = false
                        }
                    }
                }
            }
        }
        .alert("Reset Onboarding", isPresented: $showResetOnboardingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.hasCompletedOnboarding = false
            }
        } message: {
            Text("This will reset the onboarding flow. You'll need to restart the app to see it again.")
        }
    }
}

#Preview {
    SettingsView()
}
