//
//  NotificationReminderSheet.swift
//  SHL
//

import SwiftUI

struct NotificationReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pushManager = PushNotificationManager.shared

    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 24)

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.accent)
                .padding(.bottom, 20)

            // Header
            VStack(spacing: 12) {
                Text("Stay in the Game")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Never miss a moment from your favorite teams")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 12) {
                    ReminderFeatureRow(icon: "bell.fill", text: "Get notified when games start and goals are scored")
                    ReminderFeatureRow(icon: "sportscourt.fill", text: "Follow live scores on your Lock Screen")
                    ReminderFeatureRow(icon: "star.fill", text: "Personalized updates for your teams")
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
            .padding(.bottom, 24)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    onEnable()
                } label: {
                    Text("Enable Notifications")
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
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Reminder Feature Row

private struct ReminderFeatureRow: View {
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
    NotificationReminderSheet(
        onEnable: {},
        onSkip: {}
    )
}
