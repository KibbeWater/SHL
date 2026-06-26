//
//  FavoriteTeamPageView.swift
//  SHL
//
//  Onboarding step 3 — pick one favorite team from the followed set.
//

import SwiftUI

struct FavoriteTeamPageView: View {
    let allTeams: [Team]
    let selectedTeamIds: Set<String>
    @Binding var favoriteTeamId: String?
    let onContinue: () -> Void
    let onSkip: () -> Void

    private var availableTeams: [Team] {
        if selectedTeamIds.isEmpty {
            return allTeams.filter { !$0.id.isEmpty }.sorted { $0.name < $1.name }
        } else {
            return allTeams.filter { selectedTeamIds.contains($0.id) }.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Pick Your Favorite",
                subtitle: "We'll put this team front and center on your home screen."
            )

            if selectedTeamIds.isEmpty {
                Label("Select teams in the previous step to choose a favorite", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Rink.gold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .RinkSpace.xl)
                    .padding(.bottom, .RinkSpace.sm)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: .RinkSpace.md)], spacing: .RinkSpace.md) {
                    ForEach(availableTeams) { team in
                        OnboardingTeamCell(
                            team: team,
                            isSelected: favoriteTeamId == team.id,
                            accent: Rink.gold,
                            badge: "star.fill"
                        ) {
                            withAnimation(.snappy) {
                                favoriteTeamId = (favoriteTeamId == team.id) ? nil : team.id
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, .RinkSpace.lg)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            OnboardingFooter(
                primaryTitle: "Continue",
                onPrimary: onContinue,
                secondaryTitle: "Skip this step",
                onSecondary: onSkip
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        RinkAmbientBackground(.arena)
        FavoriteTeamPageView(
            allTeams: Team.onboardingPreviewTeams,
            selectedTeamIds: ["t-FHC", "t-LHF", "t-SAIK", "t-RBK"],
            favoriteTeamId: .constant("t-FHC"),
            onContinue: {},
            onSkip: {}
        )
    }
    .preferredColorScheme(.dark)
}
