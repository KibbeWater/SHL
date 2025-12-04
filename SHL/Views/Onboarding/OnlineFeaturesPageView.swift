//
//  OnlineFeaturesPageView.swift
//  SHL
//
//  Created by Claude Code
//

import SwiftUI

struct OnlineFeaturesPageView: View {
    @Binding var enableOnlineFeatures: Bool
    let onFinish: () -> Void
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
                Text("Enable Sync & Notifications")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "bell.fill", text: "Get notified about match starts, live goals, and final scores for your teams")
                    FeatureRow(icon: "sportscourt.fill", text: "Track live games on your Lock Screen with Live Activities")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Sync your team preferences and settings across all your devices")
                    FeatureRow(icon: "lock.shield.fill", text: "Your data is encrypted and stored securely via iCloud")
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(.bottom, 32)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    enableOnlineFeatures = true
                    onFinish()
                } label: {
                    Text("Enable Sync & Notifications")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    enableOnlineFeatures = false
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
    OnlineFeaturesPageView(
        enableOnlineFeatures: .constant(false),
        onFinish: {},
        onSkip: {}
    )
}
