//
//  NotificationSettingsView.swift
//  SHL
//
//  Dedicated notification preferences screen with a per-team alert level.
//

import SwiftUI
import UIKit

// MARK: - Level display

extension TeamNotificationLevel {
    /// Short, client-friendly title shown in the picker.
    var title: String {
        switch self {
        case .all: return "All alerts"
        case .finalOnly: return "Final score"
        case .off: return "Off"
        }
    }

    /// One-line explanation of what each level delivers.
    var summary: String {
        switch self {
        case .all: return "Game start, every goal, and the final score"
        case .finalOnly: return "Just the final score when the game ends"
        case .off: return "No notifications for this team"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "bell.badge.fill"
        case .finalOnly: return "flag.checkered"
        case .off: return "bell.slash"
        }
    }
}

// MARK: - View

struct NotificationSettingsView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var pushManager = PushNotificationManager.shared

    @State private var isRequestingPermission = false

    private var orderedTeams: [InterestedTeam] {
        let favoriteId = settings.getFavoriteTeamId()
        return settings.getInterestedTeams().sorted { lhs, rhs in
            if lhs.id == favoriteId { return true }
            if rhs.id == favoriteId { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        List {
            permissionSection

            if orderedTeams.isEmpty {
                Section {
                    emptyTeams
                }
            } else {
                Section {
                    ForEach(orderedTeams) { team in
                        teamRow(team)
                    }
                } header: {
                    Text("Your Teams")
                } footer: {
                    Text("Choose how much you want to hear about each team. Goal alerts only arrive on “All alerts”.")
                }
            }

            if #available(iOS 17.2, *) {
                Section {
                    Toggle("Live Activity on Lock Screen", isOn: autoStartLiveActivityBinding)
                } footer: {
                    Text("Automatically shows a live score on your Lock Screen when your teams play, so you can follow along without opening the app.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await pushManager.checkAndUpdatePermissionStatus()
            await settings.hydrateInterestedTeamsFromBackend()
        }
    }

    // MARK: - Permission

    @ViewBuilder
    private var permissionSection: some View {
        switch pushManager.permissionStatus {
        case .notDetermined:
            Section {
                Button {
                    Task {
                        isRequestingPermission = true
                        _ = await pushManager.requestPermissionsAndRegister()
                        await pushManager.checkAndUpdatePermissionStatus()
                        isRequestingPermission = false
                    }
                } label: {
                    HStack {
                        Label("Turn On Notifications", systemImage: "bell.badge.fill")
                        Spacer()
                        if isRequestingPermission {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRequestingPermission)
            } footer: {
                Text("Allow notifications to get goals, game starts, and final scores for the teams you follow.")
            }

        case .denied:
            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Settings to Allow Notifications", systemImage: "gear")
                }
            } header: {
                Label("Notifications are off", systemImage: "bell.slash.fill")
                    .foregroundStyle(.orange)
            } footer: {
                Text("Notifications are turned off for SHL in iOS Settings. Turn them on to receive alerts for your teams.")
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Team row

    private func teamRow(_ team: InterestedTeam) -> some View {
        let isFavorite = team.id == settings.getFavoriteTeamId()
        // A navigation-link picker owns the whole row (label + trailing value) and reflows
        // gracefully at large Dynamic Type, where a trailing .menu picker overlaps.
        return Picker(selection: levelBinding(for: team)) {
            ForEach(TeamNotificationLevel.allCases) { level in
                Text(level.title).tag(level)
            }
        } label: {
            HStack(spacing: 12) {
                TeamLogoView(teamCode: team.code, iconURL: nil, size: .custom(28))
                    .frame(width: 32, height: 32)

                Text(team.name)
                    .foregroundStyle(.primary)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favourite team")
                }
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var emptyTeams: some View {
        VStack(spacing: 6) {
            Image(systemName: "bell.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No teams followed yet")
                .font(.subheadline.weight(.medium))
            Text("Follow a team to choose what you get notified about.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .listRowSeparator(.hidden)
    }

    // MARK: - Bindings

    private func levelBinding(for team: InterestedTeam) -> Binding<TeamNotificationLevel> {
        Binding(
            get: { settings.notificationLevel(for: team.id) },
            set: { settings.setNotificationLevel($0, for: team.id) }
        )
    }

    private var autoStartLiveActivityBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationSettings.autoStartLiveActivity },
            set: { settings.notificationSettings = NotificationSettings(autoStartLiveActivity: $0) }
        )
    }
}

// MARK: - Previews

private func seedPreviewSettings() -> Settings {
    let settings = Settings.shared
    let teams = [
        InterestedTeam(id: "1", name: "Frölunda HC", code: "FHC", city: "Göteborg"),
        InterestedTeam(id: "2", name: "Djurgården", code: "DIF", city: "Stockholm"),
        InterestedTeam(id: "3", name: "Skellefteå AIK", code: "SKE", city: "Skellefteå")
    ]
    settings.cacheInterestedTeams(teams)
    settings.setFavoriteTeamId("1")
    settings.cacheInterestedTeamLevels([
        "1": TeamNotificationLevel.all.rawValue,
        "2": TeamNotificationLevel.finalOnly.rawValue,
        "3": TeamNotificationLevel.off.rawValue
    ])
    return settings
}

#Preview("iPhone") {
    _ = seedPreviewSettings()
    return NavigationStack { NotificationSettingsView() }
}

#Preview("Dark") {
    _ = seedPreviewSettings()
    return NavigationStack { NotificationSettingsView() }
        .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    _ = seedPreviewSettings()
    return NavigationStack { NotificationSettingsView() }
}
