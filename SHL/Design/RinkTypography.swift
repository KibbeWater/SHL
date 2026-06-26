//
//  RinkTypography.swift
//  SHL
//
//  Type scale. We lean on system text styles so everything scales with Dynamic
//  Type automatically — never hardcoded point sizes. Where Together chose a
//  rounded, warm voice, Rink uses crisp default SF Pro with heavy weights and
//  monospaced numerics — the authoritative, broadcast-graphics feel of a
//  scoreboard. Scores, clocks, and standings always use `.monospacedDigit()` so
//  digits never jitter as they tick.
//

import SwiftUI

extension Font {
    /// Display — the biggest moment on screen (hero team name, a featured score line).
    static var rinkDisplay: Font { .system(.largeTitle, weight: .heavy) }

    /// Title — screen + section titles.
    static var rinkTitle: Font { .system(.title2, weight: .bold) }

    /// Card title — the headline inside a card.
    static var rinkCardTitle: Font { .system(.title3, weight: .semibold) }

    /// Headline — a label sitting above a value.
    static var rinkHeadline: Font { .headline }

    /// Body — list + paragraph copy.
    static var rinkBody: Font { .body }

    /// Caption — timestamps, venue, meta.
    static var rinkCaption: Font { .caption.weight(.medium) }

    /// Big scoreboard number — monospaced so a 1 is as wide as an 8.
    static var rinkScore: Font { .system(.largeTitle, weight: .heavy).monospacedDigit() }

    /// Inline numeric — points, clocks, smaller scores.
    static var rinkNumeric: Font { .system(.title3, weight: .semibold).monospacedDigit() }
}

extension View {
    /// The small uppercase "eyebrow" that sits above a section or hero — tracked
    /// out, weighty, and quiet. Pair with a tinted SF Symbol for section accents.
    func rinkKicker(_ color: Color = .secondary) -> some View {
        self.font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(color)
    }
}

#Preview("Type scale") {
    VStack(alignment: .leading, spacing: 14) {
        Text("FEATURED").rinkKicker(Rink.ice)
        Text("Frölunda HC").font(.rinkDisplay)
        Text("Section title").font(.rinkTitle)
        Text("Card title").font(.rinkCardTitle)
        Text("Headline label").font(.rinkHeadline)
        Text("Body copy that wraps across a couple of lines to show the reading voice.")
            .font(.rinkBody)
        Text("Caption · Be-Ge Hockey Center").font(.rinkCaption).foregroundStyle(.secondary)
        HStack(spacing: 16) {
            Text("3").font(.rinkScore)
            Text("–").font(.rinkScore).foregroundStyle(.secondary)
            Text("2").font(.rinkScore)
            Text("108 pts").font(.rinkNumeric).foregroundStyle(.secondary)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Rink.canvas)
}

#Preview("Type scale · Dark") {
    VStack(alignment: .leading, spacing: 14) {
        Text("LIVE").rinkKicker(Rink.goal)
        Text("2 – 1").font(.rinkScore)
        Text("Section title").font(.rinkTitle)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Rink.canvas)
    .preferredColorScheme(.dark)
}
