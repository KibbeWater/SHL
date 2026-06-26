//
//  RinkBackground.swift
//  SHL
//
//  The ambient backdrop for the home scene. Rather than a flat gradient or a
//  busy mesh, it layers a few large, soft radial glows over a deep base — an
//  "arena spotlight / aurora" feel that has organic depth without a visible
//  seam. The glows drift slowly (stilled under Reduce Motion) and can be tinted
//  by the user's favorite team for a quiet bit of personalization.
//
//  Works on iOS 17+ (no `MeshGradient` dependency). Cheap: three radial
//  gradients plus one Core-Animation drift, so it sits happily behind a
//  scrolling feed.
//

import SwiftUI
import UIKit

struct RinkAmbientBackground: View {
    enum Theme: Equatable {
        /// Cool brand default.
        case ice
        /// Deep broadcast night — the home default.
        case arena
        /// Nordic aurora — glacier/violet/ice.
        case aurora
        /// Cool glows with one blob tinted by a team's color.
        case team(Color)
    }

    var theme: Theme
    var animated: Bool

    init(_ theme: Theme = .arena, animated: Bool = true) {
        self.theme = theme
        self.animated = animated
    }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isDark: Bool { scheme == .dark }
    private var active: Bool { animated && !reduceMotion }
    private var blend: BlendMode { isDark ? .screen : .normal }

    var body: some View {
        let g = glows
        ZStack {
            (isDark ? RinkNight.base : Color(.systemBackground))
                .ignoresSafeArea()

            GlowBlob(color: g.0, size: 600, alignment: .topTrailing,
                     offset: CGSize(width: 90, height: -150),
                     drift: CGSize(width: -26, height: 20), blend: blend, active: active)
            GlowBlob(color: g.1, size: 470, alignment: .topLeading,
                     offset: CGSize(width: -90, height: -30),
                     drift: CGSize(width: 22, height: -16), blend: blend, active: active)
            GlowBlob(color: g.2, size: 560, alignment: .bottomTrailing,
                     offset: CGSize(width: 50, height: 130),
                     drift: CGSize(width: -18, height: -24), blend: blend, active: active)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// (primary, secondary, tertiary) glow colors, opacity baked in. Dark mode
    /// glows are luminous (they `.screen` over the deep base); light mode glows
    /// are soft tints (they sit `.normal` over the system background).
    private var glows: (Color, Color, Color) {
        let o: (Double, Double, Double) = isDark ? (0.36, 0.26, 0.20) : (0.16, 0.12, 0.09)
        switch theme {
        case .ice:
            return (Rink.ice.opacity(o.0), Rink.glacier.opacity(o.1), Rink.ice.opacity(o.2))
        case .arena:
            return (Rink.ice.opacity(o.0), Rink.glacier.opacity(o.1), Self.violet.opacity(o.2))
        case .aurora:
            return (Rink.glacier.opacity(o.0), Self.violet.opacity(o.1), Rink.ice.opacity(o.2))
        case .team(let c):
            return (Rink.ice.opacity(o.0), c.opacity(isDark ? o.1 + 0.06 : o.1 + 0.02), Rink.glacier.opacity(o.2))
        }
    }

    private static let violet = Color(light: UIColor(red: 0.45, green: 0.40, blue: 0.85, alpha: 1),
                                      dark:  UIColor(red: 0.52, green: 0.46, blue: 0.92, alpha: 1))
}

/// One large, soft radial glow that drifts slowly on a cheap Core-Animation loop.
private struct GlowBlob: View {
    let color: Color
    let size: CGFloat
    let alignment: Alignment
    let offset: CGSize
    let drift: CGSize
    let blend: BlendMode
    let active: Bool

    @State private var on = false

    var body: some View {
        // The flexible Color.clear is the sizing view; the fixed-size circle rides
        // along as an overlay so its 600-pt width never propagates up the layout
        // and stretches the screen.
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: alignment) {
                Circle()
                    .fill(RadialGradient(colors: [color, .clear], center: .center, startRadius: 0, endRadius: size / 2))
                    .frame(width: size, height: size)
                    .offset(x: offset.width + (on ? drift.width : 0),
                            y: offset.height + (on ? drift.height : 0))
                    .blendMode(blend)
            }
            .accessibilityHidden(true)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 13).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

/// Deep dark-mode canvas — a lifted slate so night reads as a cold arena, not a
/// flat black void.
private enum RinkNight {
    static let base = Color(red: 0.05, green: 0.07, blue: 0.11)
}

#Preview("Arena · Dark") {
    RinkAmbientBackground(.arena).preferredColorScheme(.dark)
}
#Preview("Aurora · Dark") {
    RinkAmbientBackground(.aurora).preferredColorScheme(.dark)
}
#Preview("Team · Dark") {
    RinkAmbientBackground(.team(Rink.goal)).preferredColorScheme(.dark)
}
#Preview("Ice · Light") {
    RinkAmbientBackground(.ice)
}
