//
//  RinkGlow.swift
//  SHL
//
//  Depth & glow helpers — soft layered shadows that give cards and the hero a
//  physical, lifted feel rather than the flat slap-it-on-the-canvas look that
//  makes generated UI feel sterile.
//

import SwiftUI

extension View {
    /// Standard card lift — a single soft tinted shadow.
    ///
    /// We deliberately use **one** shadow rather than the common stacked
    /// "small dark + tinted bloom" pair. Each SwiftUI `.shadow` triggers a
    /// separate offscreen pass on the render server, and the home feed shows
    /// many cards at once; one shadow is plenty for the lift we want and keeps
    /// scrolling smooth.
    func rinkCardLift(tint: Color = .black, radius: CGFloat = 14) -> some View {
        self.shadow(color: tint.opacity(0.16), radius: radius, x: 0, y: 6)
    }

    /// Heavier hero lift — used for the top-of-screen featured panel only. Tinted
    /// with `ice` so the hero feels lit from the rink rather than just dropped on a
    /// surface. Pass a team color to tint the lift to the matchup.
    func rinkHeroLift(tint: Color = Rink.ice) -> some View {
        self.shadow(color: tint.opacity(0.28), radius: 22, x: 0, y: 12)
    }

    /// Pressable: gently scales with a spring on touch. Add `.sensoryFeedback`
    /// at the call site for haptics on meaningful taps.
    func rinkPressable() -> some View {
        self.modifier(RinkPressableModifier())
    }
}

private struct RinkPressableModifier: ViewModifier {
    @State private var pressed = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
            .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 200,
                                pressing: { pressed = $0 },
                                perform: {})
    }
}

#Preview("Lift") {
    VStack(spacing: 28) {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.regularMaterial)
            .frame(height: 110)
            .overlay(Text("Card lift").font(.rinkCardTitle))
            .rinkCardLift()
            .padding(.horizontal)

        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Rink.iceGradient)
            .frame(height: 160)
            .overlay(Text("Hero lift").font(.rinkCardTitle).foregroundStyle(.white))
            .rinkHeroLift()
            .padding(.horizontal)
    }
    .padding(.vertical, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Rink.canvas)
}
