//
//  RinkPalette.swift
//  SHL
//
//  The "Rink" design system — a cool, broadcast-quality hockey aesthetic built
//  around ice, arena light, and the red goal lamp. Every decorative accent is
//  paired (`Color(light:dark:)`) and anchored to system semantics, so Dark Mode,
//  Increase Contrast, and Vibrancy all work for free.
//
//  Rule of thumb:
//  • Use `Color(.systemX)` (via `Rink.canvas` / `surface` / `raised`) wherever you
//    would otherwise reach for hardcoded white/black.
//  • Use a `Rink.*` accent for brand moments — the live lamp, the featured hero,
//    the favorite-team spotlight, standings call-outs.
//

import SwiftUI
import UIKit

/// Rink's palette namespace. Cool and confident: a single electric **ice** blue
/// carries the brand, **glacier** cyan partners it in gradients, **goal** red is
/// reserved for the live lamp and scoring, and **gold** marks the podium.
enum Rink {
    // MARK: - Accents

    /// Primary brand accent — an electric ice-blue. Tints, links, the active state.
    /// Brighter in the dark so it reads as glowing arena light rather than navy.
    static let ice = Color(light: UIColor(red: 0.00, green: 0.52, blue: 0.92, alpha: 1),
                           dark:  UIColor(red: 0.32, green: 0.72, blue: 1.00, alpha: 1))

    /// Secondary cyan — the gradient partner to `ice`, and a cool highlight on its own.
    static let glacier = Color(light: UIColor(red: 0.24, green: 0.78, blue: 0.94, alpha: 1),
                               dark:  UIColor(red: 0.38, green: 0.83, blue: 0.99, alpha: 1))

    /// Pale frost — card washes, low-emphasis fills, the soft side of gradients.
    static let frost = Color(light: UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1),
                             dark:  UIColor(red: 0.13, green: 0.18, blue: 0.27, alpha: 1))

    /// Cool neutral graphite — hairlines, secondary glyphs on glass, muted chrome.
    static let steel = Color(light: UIColor(red: 0.42, green: 0.47, blue: 0.55, alpha: 1),
                             dark:  UIColor(red: 0.60, green: 0.66, blue: 0.74, alpha: 1))

    /// The goal lamp. Reserved for LIVE, the moment a goal lands, and true alerts.
    /// Do not use it for ordinary emphasis — its scarcity is what makes it read as "live".
    static let goal = Color(light: UIColor(red: 0.89, green: 0.15, blue: 0.21, alpha: 1),
                            dark:  UIColor(red: 1.00, green: 0.34, blue: 0.39, alpha: 1))

    /// Podium gold — the leader's rank, the playoff line, championship history.
    static let gold = Color(light: UIColor(red: 0.78, green: 0.58, blue: 0.13, alpha: 1),
                            dark:  UIColor(red: 1.00, green: 0.81, blue: 0.34, alpha: 1))

    /// Foreground for text sitting directly on full-bleed cool scenes (the hero,
    /// the ambient background) — a deep navy-charcoal that stays cool without
    /// losing contrast. Use `.primary` on cards; use `ink` on immersive scenes.
    static let ink = Color(light: UIColor(red: 0.09, green: 0.13, blue: 0.20, alpha: 1),
                           dark:  UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1))

    // MARK: - Semantic Surfaces

    /// Base canvas — defer to the system so it tracks elevation + contrast settings.
    static var canvas: Color { Color(.systemBackground) }
    static var surface: Color { Color(.secondarySystemBackground) }
    static var raised: Color { Color(.tertiarySystemBackground) }

    // MARK: - Gradients

    /// Primary brand gradient — ice → glacier. Hero accents, prominent buttons.
    static let iceGradient = LinearGradient(
        colors: [ice, glacier],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Soft frost wash for plain card surfaces that still want a hint of cold.
    static let frostWash = LinearGradient(
        colors: [glacier.opacity(0.22), ice.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// The live gradient — goal red bleeding into a hot ember. Behind LIVE badges
    /// and the pulse on an in-progress hero.
    static let liveGradient = LinearGradient(
        colors: [goal, Color(light: UIColor(red: 1.00, green: 0.36, blue: 0.26, alpha: 1),
                             dark:  UIColor(red: 1.00, green: 0.50, blue: 0.36, alpha: 1))],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Podium gradient for the leader card / champion flourishes.
    static let goldGradient = LinearGradient(
        colors: [gold, Color(light: UIColor(red: 0.90, green: 0.72, blue: 0.28, alpha: 1),
                            dark:  UIColor(red: 1.00, green: 0.88, blue: 0.52, alpha: 1))],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// A Nordic aurora — glacier → ice → violet. Used only for the immersive
    /// ambient background's flourish, never behind body copy.
    static let auroraGradient = LinearGradient(
        colors: [glacier.opacity(0.7), ice.opacity(0.6),
                 Color(light: UIColor(red: 0.45, green: 0.40, blue: 0.85, alpha: 1),
                       dark:  UIColor(red: 0.52, green: 0.46, blue: 0.92, alpha: 1)).opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Adaptive Color Helpers

extension Color {
    /// Blend this color toward black by `amount` (0...1). Used to turn a team's
    /// bright logo color into a background dark enough for white text to sit on.
    func darkened(by amount: CGFloat = 0.4) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        let k = 1 - amount
        return Color(red: Double(r * k), green: Double(g * k), blue: Double(b * k), opacity: Double(a))
    }

    /// Blend this color toward white by `amount` (0...1). Used for soft team-tinted
    /// nodes in the light-mode mesh, where an opaque pale tint reads better than alpha.
    func lightened(by amount: CGFloat = 0.5) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        return Color(red: Double(r + (1 - r) * amount),
                     green: Double(g + (1 - g) * amount),
                     blue: Double(b + (1 - b) * amount),
                     opacity: Double(a))
    }

    /// Build a color that resolves dynamically between light and dark mode — the
    /// backbone of the palette, so every decorative accent adapts without a second
    /// asset entry.
    init(light: UIColor, dark: UIColor) {
        self = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Parse a hex string (`"0085E6"`, `"#0085E6"`, or 8-digit with alpha). Used to
    /// turn the backend's per-team `TeamColors.primary` hex into a SwiftUI color.
    init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }

        var rgba: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&rgba)

        let r, g, b, a: Double
        switch trimmed.count {
        case 6:
            r = Double((rgba & 0xFF0000) >> 16) / 255.0
            g = Double((rgba & 0x00FF00) >> 8)  / 255.0
            b = Double( rgba & 0x0000FF)        / 255.0
            a = 1.0
        case 8:
            r = Double((rgba & 0xFF000000) >> 24) / 255.0
            g = Double((rgba & 0x00FF0000) >> 16) / 255.0
            b = Double((rgba & 0x0000FF00) >> 8)  / 255.0
            a = Double( rgba & 0x000000FF)        / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Tint Convenience

extension View {
    /// Applies Rink's brand tint. Set once at the app/scene root; controls inherit it.
    func rinkTint() -> some View {
        self.tint(Rink.ice)
    }
}

#Preview("Swatches") {
    func swatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(height: 56)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08)))
            Text(name).font(.caption2).foregroundStyle(.secondary)
        }
    }
    return ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
            swatch("ice", Rink.ice)
            swatch("glacier", Rink.glacier)
            swatch("frost", Rink.frost)
            swatch("steel", Rink.steel)
            swatch("goal", Rink.goal)
            swatch("gold", Rink.gold)
            swatch("ink", Rink.ink)
        }
        .padding()
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Rink.iceGradient).frame(height: 60)
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Rink.liveGradient).frame(height: 60)
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Rink.goldGradient).frame(height: 60)
        }
        .padding(.horizontal)
    }
    .background(Rink.canvas)
}

#Preview("Swatches · Dark") {
    HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Rink.ice)
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Rink.glacier)
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Rink.goal)
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Rink.gold)
    }
    .frame(height: 80)
    .padding()
    .background(Rink.canvas)
    .preferredColorScheme(.dark)
}
