//
//  OnboardingContainerView.swift
//  SHL
//
//  Created by Claude Code
//

import PostHog
import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var selectedTeamIds: Set<String> = []
    @State private var favoriteTeamId: String? = nil
    @State private var enableOnlineFeatures = false  // User chooses via buttons
    @State private var allTeams: [Team] = []
    @State private var isLoadingTeams = true
    @State private var loadError: Error?

    // Analytics tracking
    @State private var onboardingStartTime: Date = Date()
    @State private var skippedTeamSelection = false
    @State private var skippedFavoriteTeam = false

    private let api = SHLAPIClient.shared
    private let settings = Settings.shared

    var body: some View {
        ZStack {
            if isLoadingTeams {
                // Loading state
                VStack {
                    Spacer()

                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Loading teams...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
            } else if loadError != nil {
                // Error state
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Failed to load teams")
                        .font(.headline)

                    Text("Please check your connection and try again")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        Task {
                            await loadTeams()
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)

                    Button("Skip Setup") {
                        completeOnboarding()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
            } else {
                // Onboarding pages
                TabView(selection: $currentPage) {
                    WelcomePageView(
                        onContinue: {
                            withAnimation {
                                currentPage = 1
                            }
                            trackPageView(page: 0, pageName: "welcome")
                        }
                    )
                    .tag(0)
                    .onAppear {
                        if currentPage == 0 {
                            trackOnboardingStarted()
                        }
                    }

                    TeamSelectionPageView(
                        allTeams: allTeams,
                        selectedTeamIds: $selectedTeamIds,
                        onContinue: {
                            withAnimation {
                                currentPage = 2
                            }
                            trackPageView(page: 1, pageName: "team_selection")
                            trackTeamSelection(skipped: false)
                        },
                        onSkip: {
                            withAnimation {
                                currentPage = 2
                            }
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
                            withAnimation {
                                currentPage = 3
                            }
                            trackPageView(page: 2, pageName: "favorite_team")
                            trackFavoriteTeamSelection(skipped: false)
                        },
                        onSkip: {
                            withAnimation {
                                currentPage = 3
                            }
                            skippedFavoriteTeam = true
                            trackPageView(page: 2, pageName: "favorite_team")
                            trackFavoriteTeamSelection(skipped: true)
                        }
                    )
                    .tag(2)

                    OnlineFeaturesPageView(
                        enableOnlineFeatures: $enableOnlineFeatures,
                        onFinish: {
                            trackPageView(page: 3, pageName: "online_features")
                            trackOnlineFeaturesSelection(enabled: true)
                            completeOnboarding()
                        },
                        onSkip: {
                            trackPageView(page: 3, pageName: "online_features")
                            trackOnlineFeaturesSelection(enabled: false)
                            completeOnboarding()
                        }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .task {
            await loadTeams()
        }
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

        // Save favorite team
        if let favoriteTeamId = favoriteTeamId, selectedTeamIds.contains(favoriteTeamId) {
            settings.setFavoriteTeamId(favoriteTeamId)
        }

        // Enable online features if toggled
        if enableOnlineFeatures {
            settings.userManagementEnabled = true
        }

        // Mark onboarding as complete
        settings.completeOnboarding()

        // Track onboarding completion
        trackOnboardingCompleted()

        // Dismiss onboarding
        dismiss()
    }

    // MARK: - Analytics Tracking

    private func trackOnboardingStarted() {
        #if !DEBUG
        PostHogSDK.shared.capture(
            "onboarding_started",
            properties: [
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        #endif
    }

    private func trackPageView(page: Int, pageName: String) {
        #if !DEBUG
        PostHogSDK.shared.capture(
            "onboarding_page_viewed",
            properties: [
                "page_number": page,
                "page_name": pageName,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        #endif
    }

    private func trackTeamSelection(skipped: Bool) {
        #if !DEBUG
        PostHogSDK.shared.capture(
            "onboarding_team_selection",
            properties: [
                "skipped": skipped,
                "teams_selected_count": selectedTeamIds.count,
                "teams_selected": skipped ? [] : Array(selectedTeamIds)
            ]
        )
        #endif
    }

    private func trackFavoriteTeamSelection(skipped: Bool) {
        #if !DEBUG
        PostHogSDK.shared.capture(
            "onboarding_favorite_team",
            properties: [
                "skipped": skipped,
                "has_favorite": favoriteTeamId != nil,
                "favorite_team_id": favoriteTeamId ?? ""
            ]
        )
        #endif
    }

    private func trackOnlineFeaturesSelection(enabled: Bool) {
        #if !DEBUG
        PostHogSDK.shared.capture(
            "onboarding_online_features",
            properties: [
                "enabled": enabled,
                "action": enabled ? "enable_now" : "not_now"
            ]
        )
        #endif
    }

    private func trackOnboardingCompleted() {
        let duration = Date().timeIntervalSince(onboardingStartTime)

        #if !DEBUG
        PostHogSDK.shared.capture(
            "onboarding_completed",
            properties: [
                "duration_seconds": duration,
                "teams_selected_count": selectedTeamIds.count,
                "has_favorite_team": favoriteTeamId != nil,
                "sync_enabled": enableOnlineFeatures,
                "skipped_team_selection": skippedTeamSelection,
                "skipped_favorite_team": skippedFavoriteTeam,
                "teams_selected": Array(selectedTeamIds),
                "favorite_team_id": favoriteTeamId ?? ""
            ]
        )
        #endif
    }
}

#Preview {
    OnboardingContainerView()
}
