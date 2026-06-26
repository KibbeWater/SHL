//
//  SettingsView.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 4/10/24.
//

import SwiftUI
import UIKit

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
    @State private var showFeedback = false

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

    /// Prominent, brand-gradient call-to-action at the top of Settings.
    private var feedbackPromoSection: some View {
        Section {
            Button {
                showFeedback = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(.white.opacity(0.22)).frame(width: 46, height: 46)
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Share Feedback")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Suggest a feature, report a bug, or tell us what you think.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Rink.iceGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Rink.ice.opacity(0.3), radius: 10, y: 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    var body: some View {
        List {
            feedbackPromoSection

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
        .sheet(isPresented: $showFeedback) {
            FeedbackSheet()
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

// MARK: - Feedback

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case suggestion
    case improvement
    case bug
    case general

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .suggestion: return String(localized: "Suggestion")
        case .improvement: return String(localized: "Improvement")
        case .bug: return String(localized: "Bug")
        case .general: return String(localized: "General")
        }
    }

    var iconName: String {
        switch self {
        case .suggestion: return "lightbulb"
        case .improvement: return "wand.and.stars"
        case .bug: return "ladybug"
        case .general: return "bubble.left.and.text.bubble"
        }
    }

    var placeholder: String {
        switch self {
        case .suggestion: return String(localized: "What would you love to see in the app?")
        case .improvement: return String(localized: "What could work better, and how?")
        case .bug: return String(localized: "What happened, and what did you expect instead?")
        case .general: return String(localized: "Anything you'd like to share with us…")
        }
    }
}

/// A lightweight feedback composer — pick a category, write a note, send. Diagnostic
/// metadata (app/OS/device) is attached silently; the submitter is identified by the
/// auth token on the backend.
struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var category: FeedbackCategory = .suggestion
    @State private var message: String = ""
    @State private var phase: Phase = .editing
    @State private var errorMessage: String?
    @State private var successTick = 0
    @FocusState private var editorFocused: Bool

    private enum Phase { case editing, sending, success }

    private var trimmed: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSend: Bool { !trimmed.isEmpty && phase != .sending }

    var body: some View {
        NavigationStack {
            ZStack {
                RinkAmbientBackground(.arena)
                if phase == .success {
                    successView.transition(.scale.combined(with: .opacity))
                } else {
                    form
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: successTick)
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .RinkSpace.lg) {
                VStack(alignment: .leading, spacing: .RinkSpace.xs) {
                    Text("What's on your mind?").font(.rinkTitle)
                    Text("Tell us what to build, fix, or change — every note reaches the team.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                categoryPicker
                messageEditor

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Rink.goal)
                        .transition(.opacity)
                }

                RinkPrimaryButton(title: "Send Feedback", icon: "paperplane.fill",
                                  isLoading: phase == .sending, isEnabled: canSend) {
                    send()
                }
            }
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var categoryPicker: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(FeedbackCategory.allCases) { item in
                categoryChip(item)
            }
        }
        .sensoryFeedback(.selection, trigger: category)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Feedback type")
    }

    private func categoryChip(_ item: FeedbackCategory) -> some View {
        let selected = category == item
        return Button {
            withAnimation(.snappy) { category = item }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.iconName)
                    .symbolVariant(selected ? .fill : .none)
                Text(item.shortName)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Rink.iceGradient) : AnyShapeStyle(.regularMaterial))
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var messageEditor: some View {
        ZStack(alignment: .topLeading) {
            if message.isEmpty {
                Text(category.placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.leading, 6)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $message)
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.regularMaterial))
    }

    private var successView: some View {
        VStack(spacing: .RinkSpace.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Rink.ice)
            Text("Thank you!").font(.rinkTitle)
            Text("Your note is on its way to the team.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private func send() {
        editorFocused = false
        withAnimation { errorMessage = nil; phase = .sending }
        let request = SendFeedbackRequest(
            category: category.rawValue,
            message: trimmed,
            appVersion: Self.appVersion,
            osVersion: Self.osVersion,
            deviceModel: Self.deviceModel
        )
        Task {
            do {
                try await SHLAPIClient.shared.submitFeedback(request)
                successTick += 1
                withAnimation { phase = .success }
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                if phase == .success { dismiss() }
            } catch {
                withAnimation {
                    phase = .editing
                    errorMessage = String(localized: "Couldn't send. Please try again.")
                }
            }
        }
    }

    // MARK: - Diagnostic metadata

    private static var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    private static var osVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
    }
}

#Preview("Feedback") {
    FeedbackSheet()
}

#Preview("Feedback · Dark") {
    FeedbackSheet()
        .preferredColorScheme(.dark)
}
