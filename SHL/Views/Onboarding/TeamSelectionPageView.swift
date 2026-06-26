//
//  TeamSelectionPageView.swift
//  SHL
//
//  Onboarding step 2 — multi-select the teams to follow, as a grid of crests.
//

import SwiftUI

struct TeamSelectionPageView: View {
    let allTeams: [Team]
    @Binding var selectedTeamIds: Set<String>
    let onContinue: () -> Void
    let onSkip: () -> Void

    private var teams: [Team] {
        allTeams.filter { !$0.id.isEmpty }.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Follow Your Teams",
                subtitle: "Pick the teams you want to keep up with.",
                accessory: selectedTeamIds.isEmpty ? nil
                    : "\(selectedTeamIds.count) selected"
            )

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: .RinkSpace.md)], spacing: .RinkSpace.md) {
                    ForEach(teams) { team in
                        OnboardingTeamCell(
                            team: team,
                            isSelected: selectedTeamIds.contains(team.id),
                            accent: Rink.ice,
                            badge: "checkmark"
                        ) {
                            withAnimation(.snappy) {
                                if selectedTeamIds.contains(team.id) {
                                    selectedTeamIds.remove(team.id)
                                } else {
                                    selectedTeamIds.insert(team.id)
                                }
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
                secondaryTitle: "Skip",
                onSecondary: onSkip
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shared onboarding building blocks

/// A selectable team crest used by the follow + favorite steps.
struct OnboardingTeamCell: View {
    let team: Team
    let isSelected: Bool
    let accent: Color
    /// SF Symbol for the selected badge ("checkmark" to follow, "star.fill" for favorite).
    let badge: String
    let action: () -> Void

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }

    var body: some View {
        Button(action: action) {
            cellContent
                .background { cellBackground }
                .overlay(alignment: .topTrailing) { badgeView }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(team.name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var cellContent: some View {
        VStack(spacing: .RinkSpace.sm) {
            TeamLogoView(teamCode: team.code, size: .custom(48))
            Text(team.code)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .RinkSpace.md)
    }

    private var cellBackground: some View {
        let fill: Color = isSelected ? accent.opacity(0.16) : .clear
        let strokeColor: Color = isSelected ? accent : Color.primary.opacity(0.06)
        let lineWidth: CGFloat = isSelected ? 2 : 1
        return shape
            .fill(.regularMaterial)
            .overlay(shape.fill(fill))
            .overlay(shape.stroke(strokeColor, lineWidth: lineWidth))
    }

    @ViewBuilder
    private var badgeView: some View {
        if isSelected {
            Image(systemName: badge)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(accent, in: Circle())
                .padding(6)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// Standard onboarding header (title + subtitle + optional accent accessory).
struct OnboardingHeader: View {
    let title: String
    var subtitle: String? = nil
    var accessory: String? = nil

    var body: some View {
        VStack(spacing: .RinkSpace.sm) {
            Text(title)
                .font(.rinkTitle)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let accessory {
                Text(accessory)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Rink.ice)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Rink.ice.opacity(0.14), in: Capsule())
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, .RinkSpace.xl)
        .padding(.top, .RinkSpace.xl)
        .padding(.bottom, .RinkSpace.lg)
        .frame(maxWidth: 600)
    }
}

/// Standard onboarding footer (primary + secondary actions), clearing the page dots.
struct OnboardingFooter: View {
    let primaryTitle: String
    let onPrimary: () -> Void
    var secondaryTitle: String? = nil
    var onSecondary: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: .RinkSpace.sm) {
            RinkPrimaryButton(title: primaryTitle, action: onPrimary)
            if let secondaryTitle, let onSecondary {
                Button(secondaryTitle, action: onSecondary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, .RinkSpace.xl)
        .padding(.top, .RinkSpace.md)
        .padding(.bottom, .RinkSpace.xl)
    }
}

extension Team {
    static var onboardingPreviewTeams: [Team] {
        func t(_ code: String, _ name: String) -> Team {
            Team(id: "t-\(code)", name: name, code: code, city: nil, founded: nil, venue: nil,
                 golds: nil, goldYears: nil, finals: nil, finalYears: nil, iconURL: nil, isActive: true)
        }
        return [
            t("FHC", "Frölunda HC"), t("LHF", "Luleå HF"), t("SAIK", "Skellefteå AIK"),
            t("RBK", "Rögle BK"), t("FBK", "Färjestad BK"), t("VLH", "Växjö Lakers"),
            t("LIF", "Leksands IF"), t("MODO", "MoDo Hockey"), t("IKO", "IK Oskarshamn")
        ]
    }
}

#Preview {
    ZStack {
        RinkAmbientBackground(.arena)
        TeamSelectionPageView(allTeams: Team.onboardingPreviewTeams, selectedTeamIds: .constant(["t-FHC", "t-LHF"]), onContinue: {}, onSkip: {})
    }
}
