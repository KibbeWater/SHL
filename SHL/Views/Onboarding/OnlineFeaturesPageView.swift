//
//  OnlineFeaturesPageView.swift
//  SHL
//
//  Final onboarding page: primes and requests notification permission.
//

import SwiftUI

struct OnlineFeaturesPageView: View {
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accent)
                .padding(.bottom, 24)

            // Header
            VStack(spacing: 12) {
                Text("Stay in the Game")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Get alerts for your favourite team. You can fine-tune what each team notifies you about anytime.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "bell.fill", text: "Goal alerts the moment your team scores")
                    FeatureRow(icon: "clock.fill", text: "A heads-up when the game is about to start")
                    FeatureRow(icon: "sportscourt.fill", text: "Follow live scores on your Lock Screen")
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(.bottom, 32)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    onEnable()
                } label: {
                    Text("Turn On Notifications")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onSkip()
                } label: {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.accent)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnlineFeaturesPageView(onEnable: {}, onSkip: {})
}

#Preview("Dark") {
    OnlineFeaturesPageView(onEnable: {}, onSkip: {})
        .preferredColorScheme(.dark)
}
