//
//  WelcomePageView.swift
//  SHL
//
//  Onboarding step 1 — branded welcome on the Rink ambient background.
//

import SwiftUI

struct WelcomePageView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: .RinkSpace.xl) {
            Spacer()

            VStack(spacing: .RinkSpace.lg) {
                Image(systemName: "hockey.puck.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Rink.iceGradient)
                    .accessibilityHidden(true)

                Text("SHL")
                    .font(.system(size: 76, weight: .heavy))
                    .foregroundStyle(Rink.iceGradient)

                VStack(spacing: .RinkSpace.sm) {
                    Text("Welcome")
                        .font(.rinkTitle)
                    Text("Follow your teams, catch every goal, and never miss a moment.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .RinkSpace.xl)
                }
            }
            .accessibilityElement(children: .combine)

            Spacer()

            RinkPrimaryButton(title: "Get Started", icon: "arrow.right", action: onContinue)
                .frame(maxWidth: 520)
                .padding(.horizontal, .RinkSpace.xl)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        RinkAmbientBackground(.arena)
        WelcomePageView(onContinue: {})
    }
}

#Preview("Dark") {
    ZStack {
        RinkAmbientBackground(.arena)
        WelcomePageView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}
