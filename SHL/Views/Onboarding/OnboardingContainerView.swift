//
//  OnboardingContainerView.swift
//  SHL
//
//  Paged onboarding over the Rink ambient background. Visual shell only — all
//  behavior (team follow, favorite, notification permission, persistence, sync,
//  analytics) is unchanged.
//

import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var selectedTeamIds: Set<String> = []
    @State private var favoriteTeamId: String? = nil
    @State private var allTeams: [Team] = []
    @State private var isLoadingTeams = true
    @State private var loadError: Error?

    // Analytics tracking
    @State private var onboardingStartTime: Date = Date()
    @State private var skippedTeamSelection = false
    @State private var skippedFavoriteTeam = false

    private let api = SHLAPIClient.shared
    private let settings = Settings.shared

    @State private var skipAutoLoad = false

    init() {}

    #if DEBUG
    init(previewTeams: [Team]) {
        _allTeams = State(initialValue: previewTeams)
        _isLoadingTeams = State(initialValue: false)
        _skipAutoLoad = State(initialValue: true)
    }
    #endif

    var body: some View {
        ZStack {
            RinkAmbientBackground(.arena)
            content
        }
        .task { if !skipAutoLoad { await loadTeams() } }
    }

    @ViewBuilder
    private var content: some View {
        if isLoadingTeams {
            VStack(spacing: .RinkSpace.md) {
                ProgressView().controlSize(.large)
                Text("Loading teams…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if loadError != nil {
            ContentUnavailableView {
                Label("Couldn't Load Teams", systemImage: "wifi.exclamationmark")
            } description: {
                Text("Check your connection and try again.")
            } actions: {
                Button {
                    Task { await loadTeams() }
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Rink.ice)

                Button("Skip Setup") { completeOnboarding() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, .RinkSpace.xs)
            }
            .padding()
        } else {
            pages
        }
    }

    private var pages: some View {
        VStack(spacing: 0) {
            progressBar
            TabView(selection: $currentPage) {
            WelcomePageView(
                onContinue: {
                    withAnimation { currentPage = 1 }
                    trackPageView(page: 0, pageName: "welcome")
                }
            )
            .tag(0)
            .onAppear {
                if currentPage == 0 { trackOnboardingStarted() }
            }

            TeamSelectionPageView(
                allTeams: allTeams,
                selectedTeamIds: $selectedTeamIds,
                onContinue: {
                    withAnimation { currentPage = 2 }
                    trackPageView(page: 1, pageName: "team_selection")
                    trackTeamSelection(skipped: false)
                },
                onSkip: {
                    withAnimation { currentPage = 2 }
                    skippedTeamSelection = true
                    trackPageView(page: 1, pageName: "team_selection")
                    trackTeamSelection(skipped: true)
                }
            )
            .tag(1)

            FavoriteTeamPageView(
                allTeams: allTeams,
                selectedTeamIds: selectedTeamIds,
                favoriteTeamId: $favoriteTeamId,
                onContinue: {
                    withAnimation { currentPage = 3 }
                    trackPageView(page: 2, pageName: "favorite_team")
                    trackFavoriteTeamSelection(skipped: false)
                },
                onSkip: {
                    withAnimation { currentPage = 3 }
                    skippedFavoriteTeam = true
                    trackPageView(page: 2, pageName: "favorite_team")
                    trackFavoriteTeamSelection(skipped: true)
                }
            )
            .tag(2)

            OnlineFeaturesPageView(
                onEnable: {
                    trackPageView(page: 3, pageName: "notifications")
                    trackOnlineFeaturesSelection(enabled: true)
                    Task {
                        _ = await PushNotificationManager.shared.requestPermissionsAndRegister()
                        await MainActor.run { completeOnboarding() }
                    }
                },
                onSkip: {
                    trackPageView(page: 3, pageName: "notifications")
                    trackOnlineFeaturesSelection(enabled: false)
                    completeOnboarding()
                }
            )
            .tag(3)
        }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AnyShapeStyle(Rink.ice) : AnyShapeStyle(Color.primary.opacity(0.18)))
                    .frame(width: index == currentPage ? 22 : 7, height: 7)
            }
        }
        .animation(.snappy, value: currentPage)
        .padding(.vertical, .RinkSpace.md)
        .accessibilityHidden(true)
    }

    private func loadTeams() async {
        isLoadingTeams = true
        loadError = nil

        do {
            let teams = try await api.getTeams()
            await MainActor.run {
                self.allTeams = teams
                self.isLoadingTeams = false
            }
        } catch {
            await MainActor.run {
                self.loadError = error
                self.isLoadingTeams = false
            }
        }
    }

    private func completeOnboarding() {
        // Save selected teams
        if !selectedTeamIds.isEmpty {
            let selectedTeams = allTeams.filter { selectedTeamIds.contains($0.id) }
            let interestedTeams = selectedTeams.map { team in
                InterestedTeam(
                    id: team.id,
                    name: team.name,
                    code: team.code,
                    city: team.city
                )
            }
            settings.setInterestedTeams(interestedTeams)
        }

        // Save favorite team and default it to full alerts (other teams stay off).
        if let favoriteTeamId = favoriteTeamId, selectedTeamIds.contains(favoriteTeamId) {
            settings.setFavoriteTeamId(favoriteTeamId)
            settings.setNotificationLevel(.all, for: favoriteTeamId)
        }

        // Mark onboarding complete. New users have seen the notifications step, so the
        // one-time existing-user prompt should never fire for them.
        settings.completeOnboarding()
        settings.hasPromptedExistingUserNotifications = true

        // Push the chosen teams + levels to the backend once registration is ready.
        Task { await settings.syncAllPreferencesToBackend() }

        // Track onboarding completion
        trackOnboardingCompleted()

        // Dismiss onboarding
        dismiss()
    }

    // MARK: - Analytics Tracking

    private func trackOnboardingStarted() {
        Analytics.track(.onboardingStarted)
    }

    private func trackPageView(page: Int, pageName: String) {
        Analytics.track(.onboardingPageViewed(page: page, name: pageName))
    }

    private func trackTeamSelection(skipped: Bool) {
        Analytics.track(.onboardingTeamSelection(skipped: skipped, count: selectedTeamIds.count))
    }

    private func trackFavoriteTeamSelection(skipped: Bool) {
        Analytics.track(.onboardingFavoriteTeam(skipped: skipped, hasFavorite: favoriteTeamId != nil))
    }

    private func trackOnlineFeaturesSelection(enabled: Bool) {
        Analytics.track(.onboardingOnlineFeatures(enabled: enabled))
    }

    private func trackOnboardingCompleted() {
        Analytics.track(.onboardingCompleted(
            durationSeconds: Date().timeIntervalSince(onboardingStartTime),
            teamsCount: selectedTeamIds.count,
            hasFavorite: favoriteTeamId != nil,
            skippedTeams: skippedTeamSelection,
            skippedFavorite: skippedFavoriteTeam
        ))
        // The user's teams are now set — refresh the cohort super properties.
        Analytics.refreshUserContext()
    }
}

#Preview {
    OnboardingContainerView(previewTeams: Team.onboardingPreviewTeams)
}
