//
//  RinkCard.swift
//  SHL
//
//  The reusable card surface — continuous corners, gentle padding, a soft
//  material or tinted wash. Four flavors:
//
//  • `.plain` — system material; the default for informational modules.
//  • `.frost` — a cool glacier wash over material; for cards that want a hint of ice.
//  • `.live`  — a faint goal-red wash + ring; for an in-progress moment.
//  • `.team(Color)` — washed with a team's color; the favorite-team spotlight.
//

import SwiftUI

/// Visual flavors of `RinkCard`. Defined at module scope so callers can hold a
/// style in a property without nailing down `RinkCard`'s generic `Content` type.
enum RinkCardStyle: Equatable {
    case plain
    case frost
    case live
    case team(Color)
}

struct RinkCard<Content: View>: View {
    let style: RinkCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(_ style: RinkCardStyle = .plain,
         padding: CGFloat = .RinkSpace.lg,
         cornerRadius: CGFloat = 20,
         @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background { background }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .plain:
            shape.fill(.regularMaterial)
                .overlay(shape.stroke(Color.primary.opacity(0.06), lineWidth: 1))

        case .frost:
            shape.fill(.regularMaterial)
                .overlay(shape.fill(Rink.frostWash))
                .overlay(shape.stroke(Rink.glacier.opacity(0.20), lineWidth: 1))

        case .live:
            shape.fill(.regularMaterial)
                .overlay(shape.stroke(Rink.goal.opacity(0.22), lineWidth: 1))

        case .team(let color):
            shape.fill(.regularMaterial)
                .overlay(
                    shape.fill(
                        LinearGradient(colors: [color.opacity(0.16), color.opacity(0.02)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )
                .overlay(shape.stroke(color.opacity(0.20), lineWidth: 1))
        }
    }
}

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            RinkCard(.plain) {
                Label("Plain · system material", systemImage: "square.stack")
                    .font(.rinkCardTitle)
            }
            RinkCard(.frost) {
                Label("Frost · glacier wash", systemImage: "snowflake")
                    .font(.rinkCardTitle)
            }
            RinkCard(.live) {
                Label("Live · in progress", systemImage: "dot.radiowaves.left.and.right")
                    .font(.rinkCardTitle)
            }
            RinkCard(.team(Rink.ice)) {
                Label("Team · favorite spotlight", systemImage: "star.fill")
                    .font(.rinkCardTitle)
            }
        }
        .padding()
    }
    .background(Rink.canvas)
}

#Preview("Cards · Dark") {
    VStack(spacing: 16) {
        RinkCard(.plain) { Text("Plain").font(.rinkCardTitle) }
        RinkCard(.frost) { Text("Frost").font(.rinkCardTitle) }
        RinkCard(.team(Rink.goal)) { Text("Team").font(.rinkCardTitle) }
    }
    .padding()
    .background(Rink.canvas)
    .preferredColorScheme(.dark)
}
