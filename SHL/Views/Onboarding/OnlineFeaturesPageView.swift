//
//  OnlineFeaturesPageView.swift
//  SHL
//
//  Onboarding step 4 — primes and requests notification permission.
//

import SwiftUI

struct OnlineFeaturesPageView: View {
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Rink.ice)
                .frame(width: 96, height: 96)
                .background(Rink.ice.opacity(0.12), in: Circle())
                .overlay(Circle().stroke(Rink.ice.opacity(0.25), lineWidth: 1))
                .padding(.bottom, .RinkSpace.lg)
                .accessibilityHidden(true)

            VStack(spacing: .RinkSpace.md) {
                Text("Stay in the Game")
                    .font(.rinkTitle)
                    .multilineTextAlignment(.center)

                Text("Get alerts for your team. You can fine-tune what each team notifies you about anytime.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .RinkSpace.xl)
            }

            VStack(alignment: .leading, spacing: .RinkSpace.md) {
                FeatureRow(icon: "hockey.puck.fill", text: "Goal alerts the moment your team scores")
                FeatureRow(icon: "clock.fill", text: "A heads-up when the game is about to start")
                FeatureRow(icon: "sportscourt.fill", text: "Live scores on your Lock Screen")
            }
            .padding(.horizontal, .RinkSpace.xl)
            .padding(.top, .RinkSpace.xl)
            .frame(maxWidth: 520)

            Spacer()

            OnboardingFooter(
                primaryTitle: "Turn On Notifications",
                onPrimary: onEnable,
                secondaryTitle: "Not Now",
                onSecondary: onSkip
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: .RinkSpace.md) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Rink.ice)
                .frame(width: 36, height: 36)
                .background(Rink.ice.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        RinkAmbientBackground(.arena)
        OnlineFeaturesPageView(onEnable: {}, onSkip: {})
    }
}

#Preview("Dark") {
    ZStack {
        RinkAmbientBackground(.arena)
        OnlineFeaturesPageView(onEnable: {}, onSkip: {})
    }
    .preferredColorScheme(.dark)
}
