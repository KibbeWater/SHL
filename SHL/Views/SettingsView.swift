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

    @State private var selectedTeam: String? = nil
    @State private var teams: [Team] = []
    @State private var teamsLoaded: Bool = false
    @State private var showDeleteAccountAlert = false
    @State private var devices: [Device] = []
    @State private var isLoadingDevices = false

    private let api = SHLAPIClient.shared
    
    func loadTeams() {
        Task {
            if let newTeams = try? await api.getTeams() {
                teams = newTeams.sorted(by: { ($0.name) < ($1.name) })
                teamsLoaded = true
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

            // MARK: - User Management Section

            Section {
                Toggle("Enable Account Features", isOn: settings.binding_userManagementEnabled())
                    .tint(.accentColor)

                if settings.userManagementEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Features Enabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Push notifications, cross-device sync, and personalized features are now available.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Features Disabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Enable to unlock push notifications, settings sync across devices, and personalized features.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Account features are optional. The app works fully without them. When enabled, your settings sync across devices via iCloud.")
            }

            // MARK: - Notification Settings (only if user management enabled)

            if settings.userManagementEnabled {
                Section("Notification Preferences") {
                    Toggle("Match Reminders", isOn: Binding(
                        get: { settings.notificationSettings.matchReminders },
                        set: { newValue in
                            var updated = settings.notificationSettings
                            updated.matchReminders = newValue
                            settings.notificationSettings = updated
                        }
                    ))

                    Toggle("Match Results", isOn: Binding(
                        get: { settings.notificationSettings.matchResults },
                        set: { newValue in
                            var updated = settings.notificationSettings
                            updated.matchResults = newValue
                            settings.notificationSettings = updated
                        }
                    ))

                    Toggle("Live Goals", isOn: Binding(
                        get: { settings.notificationSettings.liveGoals },
                        set: { newValue in
                            var updated = settings.notificationSettings
                            updated.liveGoals = newValue
                            settings.notificationSettings = updated
                        }
                    ))

                    Toggle("Period Updates", isOn: Binding(
                        get: { settings.notificationSettings.periodUpdates },
                        set: { newValue in
                            var updated = settings.notificationSettings
                            updated.periodUpdates = newValue
                            settings.notificationSettings = updated
                        }
                    ))

                    Toggle("Favorite Team Only", isOn: Binding(
                        get: { settings.notificationSettings.favoriteTeamOnly },
                        set: { newValue in
                            var updated = settings.notificationSettings
                            updated.favoriteTeamOnly = newValue
                            settings.notificationSettings = updated
                        }
                    ))
                }

                // MARK: - Push Notification Status

                Section("Push Notifications") {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        switch pushManager.permissionStatus {
                        case .authorized:
                            Label("Authorized", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .denied:
                            Label("Denied", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        case .notDetermined:
                            Label("Not Set", systemImage: "questionmark.circle.fill")
                                .foregroundStyle(.orange)
                        case .provisional, .ephemeral:
                            Label("Provisional", systemImage: "clock.circle.fill")
                                .foregroundStyle(.orange)
                        @unknown default:
                            Label("Unknown", systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                    .font(.caption)

                    if pushManager.permissionStatus != .authorized {
                        Button {
                            Task {
                                _ = await pushManager.requestPermissionsAndRegister()
                            }
                        } label: {
                            Label("Enable Push Notifications", systemImage: "bell.badge.fill")
                        }
                    } else {
                        HStack {
                            Text("Backend Registration")
                            Spacer()
                            if pushManager.isTokenRegisteredWithBackend {
                                Label("Registered", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if pushManager.pushToken != nil {
                                Button("Register Token") {
                                    Task {
                                        try? await pushManager.registerTokenWithBackend()
                                    }
                                }
                            } else {
                                Label("No Token", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.caption)
                    }
                }

                // MARK: - Account Management

                Section("Account Management") {
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

                        Button("Logout", role: .destructive) {
                            Task {
                                try? await authManager.logout()
                            }
                        }

                        Button("Delete Account", role: .destructive) {
                            showDeleteAccountAlert = true
                        }
                    } else {
                        Text("Not authenticated")
                            .foregroundStyle(.secondary)
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
            }

            // MARK: - Debug Tools Section

#if DEBUG
            Section("Debug Tools") {
                if settings.userManagementEnabled && authManager.isAuthenticated {
                    NavigationLink {
                        NotificationTestView()
                    } label: {
                        Label("Test Push Notifications", systemImage: "bell.badge.fill")
                    }
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
    }
}

#Preview {
    SettingsView()
}
