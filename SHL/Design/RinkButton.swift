//
//  RinkButton.swift
//  SHL
//
//  The primary / secondary call-to-action buttons. Full width, large tap target,
//  haptic on press, animated symbol when an icon is provided.
//

import SwiftUI

struct RinkPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var tapTick = 0

    var body: some View {
        Button {
            tapTick += 1
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().controlSize(.small).tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .contentTransition(.symbolEffect(.replace))
                }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(Rink.iceGradient) : AnyShapeStyle(Color.gray.opacity(0.4)))
            }
            .shadow(color: isEnabled ? Rink.ice.opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .sensoryFeedback(.impact(weight: .light), trigger: tapTick)
        .animation(.snappy, value: isEnabled)
        .animation(.snappy, value: isLoading)
    }
}

/// A softer secondary button — outlined, blends with the surface.
struct RinkSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.body.weight(.semibold)) }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Rink.ice)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Rink.ice.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        RinkPrimaryButton(title: "Set Reminder", icon: "bell.fill", action: {})
        RinkPrimaryButton(title: "Loading…", isLoading: true, action: {})
        RinkPrimaryButton(title: "Disabled", isEnabled: false, action: {})
        RinkSecondaryButton(title: "View Schedule", icon: "calendar", action: {})
    }
    .padding(24)
    .background(Rink.canvas)
}

#Preview("Buttons · Dark") {
    VStack(spacing: 16) {
        RinkPrimaryButton(title: "Set Reminder", icon: "bell.fill", action: {})
        RinkSecondaryButton(title: "View Schedule", action: {})
    }
    .padding(24)
    .background(Rink.canvas)
    .preferredColorScheme(.dark)
}
