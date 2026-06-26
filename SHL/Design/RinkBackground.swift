//
//  RinkBackground.swift
//  SHL
//
//  The ambient backdrop for the home scene. On iOS 18+ it's an animated
//  `MeshGradient` — a cool, organic field whose interior control points drift
//  slowly so the whole surface breathes. On iOS 17 it falls back to layered soft
//  radial glows that read almost identically (just not animated).
//
//  Both can be tinted by the user's favorite team for a quiet bit of
//  personalization, and both still under Reduce Motion (the mesh holds a static
//  frame, the glows stop drifting).
//
//  Performance: the mesh is GPU-rendered and updated at a capped ~20fps with
//  small point deltas, so it stays smooth behind the scrolling feed.
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
        /// Cool field with the focal glow tinted by a team's color.
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
        Group {
            if #available(iOS 18.0, *) {
                AnimatedMesh(colors: meshColors, animate: active)
            } else {
                glowLayer
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Mesh colors (iOS 18)

    /// Nine opaque nodes laid out so the brights sit at the corners and centre
    /// with the base dipping in between — organic glow, no horizontal seam.
    private var meshColors: [Color] {
        let p = isDark ? Self.darkPalette : Self.lightPalette
        let a1: Color, a2: Color, center: Color
        switch theme {
        case .ice:    (a1, a2, center) = (p.glacier, p.ice, p.ice)
        case .arena:  (a1, a2, center) = (p.glacier, p.violet, p.ice)
        case .aurora: (a1, a2, center) = (p.glacier, p.ice, p.violet)
        case .team(let c):
            (a1, a2, center) = (p.ice, p.glacier, isDark ? c.darkened(by: 0.34) : c.lightened(by: 0.58))
        }
        return [a1,      p.base, a2,
                p.base,  center, p.base,
                a2,      p.base, a1]
    }

    private struct Palette { let base, ice, glacier, violet: Color }

    private static let darkPalette = Palette(
        base:    Color(red: 0.05, green: 0.07, blue: 0.11),
        ice:     Color(red: 0.13, green: 0.40, blue: 0.72),
        glacier: Color(red: 0.14, green: 0.46, blue: 0.62),
        violet:  Color(red: 0.30, green: 0.22, blue: 0.56)
    )

    private static let lightPalette = Palette(
        base:    Color(red: 0.95, green: 0.97, blue: 1.00),
        ice:     Color(red: 0.80, green: 0.89, blue: 1.00),
        glacier: Color(red: 0.82, green: 0.93, blue: 0.99),
        violet:  Color(red: 0.87, green: 0.85, blue: 0.98)
    )

    // MARK: - Glow fallback (iOS 17)

    private var glowLayer: some View {
        let g = glows
        return ZStack {
            (isDark ? Self.darkPalette.base : Color(.systemBackground))
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
    }

    /// (primary, secondary, tertiary) glow colors with opacity baked in.
    private var glows: (Color, Color, Color) {
        let o: (Double, Double, Double) = isDark ? (0.36, 0.26, 0.20) : (0.16, 0.12, 0.09)
        switch theme {
        case .ice:    return (Rink.ice.opacity(o.0), Rink.glacier.opacity(o.1), Rink.ice.opacity(o.2))
        case .arena:  return (Rink.ice.opacity(o.0), Rink.glacier.opacity(o.1), Self.violetGlow.opacity(o.2))
        case .aurora: return (Rink.glacier.opacity(o.0), Self.violetGlow.opacity(o.1), Rink.ice.opacity(o.2))
        case .team(let c):
            return (Rink.ice.opacity(o.0), c.opacity(isDark ? o.1 + 0.06 : o.1 + 0.02), Rink.glacier.opacity(o.2))
        }
    }

    private static let violetGlow = Color(light: UIColor(red: 0.45, green: 0.40, blue: 0.85, alpha: 1),
                                          dark:  UIColor(red: 0.52, green: 0.46, blue: 0.92, alpha: 1))
}

// MARK: - Animated mesh

@available(iOS 18.0, *)
private struct AnimatedMesh: View {
    let colors: [Color]
    let animate: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !animate)) { timeline in
            let t = animate ? timeline.date.timeIntervalSinceReferenceDate : 0
            MeshGradient(width: 3, height: 3, points: Self.points(t), colors: colors, smoothsColors: true)
                .ignoresSafeArea()
        }
    }

    /// 3×3 grid. Corners pinned; the four edge-midpoints slide along their edge
    /// and the centre drifts in both axes — each on its own slow sine so the
    /// field never repeats obviously.
    static func points(_ t: TimeInterval) -> [SIMD2<Float>] {
        func o(_ base: Double, _ speed: Double, _ amp: Double, _ phase: Double = 0) -> Float {
            Float(base + sin(t * speed + phase) * amp)
        }
        return [
            .init(0, 0),
            .init(o(0.5, 0.27, 0.07), 0),
            .init(1, 0),

            .init(0, o(0.5, 0.23, 0.07, 1.0)),
            .init(o(0.5, 0.31, 0.09, 2.0), o(0.5, 0.29, 0.09, 0.5)),
            .init(1, o(0.5, 0.25, 0.07, 3.0)),

            .init(0, 1),
            .init(o(0.5, 0.21, 0.07, 4.0), 1),
            .init(1, 1)
        ]
    }
}

// MARK: - Glow blob (fallback)

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
        // along as an overlay so its width never propagates up the layout.
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
