//
//  RinkChip.swift
//  SHL
//
//  Small signal components — badges, the live lamp, last-5 form pips, and an
//  action capsule. These are the vocabulary that makes a hockey screen read at a
//  glance: a red LIVE pulse, a green-to-red form streak, a gold FINAL tag.
//

import SwiftUI

// MARK: - Badge

/// A compact capsule label. Use `.neutral` for meta (FINAL, OT, a date),
/// `.accent` for brand call-outs, `.gold` for podium/championship notes, and
/// `.live` for the goal-red in-progress tag (prefer `RinkLiveBadge` when you
/// want the pulse).
struct RinkBadge: View {
    enum Style { case neutral, accent, gold, live }

    let text: String
    var systemImage: String? = nil
    var style: Style = .neutral

    private var tint: Color {
        switch style {
        case .neutral: return Rink.steel
        case .accent:  return Rink.ice
        case .gold:    return Rink.gold
        case .live:    return Rink.goal
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption2.weight(.bold))
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .foregroundStyle(style == .neutral ? AnyShapeStyle(.secondary) : AnyShapeStyle(tint))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous).fill(tint.opacity(style == .neutral ? 0.12 : 0.16))
        )
        .accessibilityLabel(text)
    }
}

// MARK: - Live lamp

/// The pulsing LIVE indicator — a goal-red dot that breathes beside the word.
/// Stills under Reduce Motion. This is the single most important "it's happening
/// now" signal in the app, so it earns the red.
struct RinkLiveBadge: View {
    var compact: Bool = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Rink.goal)
                .frame(width: 7, height: 7)
                .scaleEffect(pulse ? 1.0 : 0.7)
                .opacity(pulse ? 1.0 : 0.5)
                .shadow(color: Rink.goal.opacity(0.6), radius: pulse ? 4 : 0)
            if !compact {
                Text("LIVE")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.0)
                    .foregroundStyle(Rink.goal)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Rink.goal.opacity(0.14)))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityLabel("Live")
    }
}

// MARK: - Form pips

/// One result in a team's recent form. Presentation-only — the home view maps
/// match results onto these.
enum RinkFormResult {
    case win, otWin, otLoss, loss, none

    var color: Color {
        switch self {
        case .win:    return Color(light: UIColor(red: 0.18, green: 0.66, blue: 0.36, alpha: 1),
                                   dark:  UIColor(red: 0.30, green: 0.80, blue: 0.46, alpha: 1))
        case .otWin:  return Color(light: UIColor(red: 0.40, green: 0.74, blue: 0.55, alpha: 1),
                                   dark:  UIColor(red: 0.52, green: 0.85, blue: 0.66, alpha: 1))
        case .otLoss: return Color(light: UIColor(red: 0.92, green: 0.58, blue: 0.20, alpha: 1),
                                   dark:  UIColor(red: 1.00, green: 0.66, blue: 0.30, alpha: 1))
        case .loss:   return Rink.goal
        case .none:   return Rink.steel.opacity(0.4)
        }
    }

    var label: String {
        switch self {
        case .win: return "win"
        case .otWin: return "overtime win"
        case .otLoss: return "overtime loss"
        case .loss: return "loss"
        case .none: return "no game"
        }
    }
}

/// Last-5 (or last-N) form, rendered as a row of colored pips, oldest → newest.
struct RinkFormPips: View {
    let results: [RinkFormResult]
    var size: CGFloat = 8

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(results.enumerated()), id: \.offset) { _, r in
                Circle().fill(r.color).frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recent form")
        .accessibilityValue(results.map(\.label).joined(separator: ", "))
    }
}

// MARK: - Action capsule

/// A capsule action chip for tight, immersive spots where a full button is too
/// heavy. `.glass` for secondary, `.prominent` for the single primary action.
struct RinkChip: View {
    enum Style { case glass, prominent }
    let title: String
    var systemImage: String? = nil
    var style: Style = .glass
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(style == .prominent ? AnyShapeStyle(.white) : AnyShapeStyle(Rink.ice))
            .background {
                switch style {
                case .glass:
                    Capsule().fill(.ultraThinMaterial)
                        .overlay(Capsule().stroke(Rink.ice.opacity(0.25), lineWidth: 1))
                case .prominent:
                    Capsule().fill(Rink.iceGradient)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Signals") {
    VStack(alignment: .leading, spacing: 20) {
        HStack(spacing: 10) {
            RinkLiveBadge()
            RinkBadge(text: "Final", style: .neutral)
            RinkBadge(text: "OT", systemImage: "clock", style: .accent)
            RinkBadge(text: "Champions", systemImage: "trophy.fill", style: .gold)
        }
        HStack(spacing: 12) {
            Text("Form").font(.rinkCaption).foregroundStyle(.secondary)
            RinkFormPips(results: [.win, .win, .otLoss, .loss, .win])
        }
        HStack(spacing: 10) {
            RinkChip(title: "Set reminder", systemImage: "bell", style: .prominent) {}
            RinkChip(title: "Schedule", systemImage: "calendar") {}
        }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Rink.canvas)
}

#Preview("Signals · Dark") {
    HStack(spacing: 10) {
        RinkLiveBadge()
        RinkBadge(text: "Final")
        RinkFormPips(results: [.win, .otWin, .loss, .win, .win])
    }
    .padding()
    .background(Rink.canvas)
    .preferredColorScheme(.dark)
}
