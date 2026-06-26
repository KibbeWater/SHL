//
//  RinkLayout.swift
//  SHL
//
//  Layout tokens + helpers. A single spacing scale keeps rhythm consistent, a
//  reading-width cap keeps content from sprawling on iPad, and one adaptive grid
//  reflows the home feed from one column on iPhone portrait to two or three on
//  iPad — no manual device breakpoints.
//

import SwiftUI

extension CGFloat {
    /// The 4-pt spacing scale. Use these instead of magic numbers so vertical
    /// rhythm stays consistent across every section.
    enum RinkSpace {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        /// Gap between top-level home sections.
        static let section: CGFloat = 28
    }
}

extension View {
    /// Cap reading-width content (cards, lists) to a sensible measure on iPad
    /// regular while leaving iPhone untouched. Centers within the available width.
    func rinkReadingWidth(_ max: CGFloat = 760) -> some View {
        self.frame(maxWidth: max)
            .frame(maxWidth: .infinity)
    }
}

/// Adaptive grid that reflows from one column on iPhone portrait up to several on
/// iPad. Pass the minimum card width; the grid figures out the column count.
struct RinkAdaptiveGrid<Content: View>: View {
    var minimum: CGFloat = 340
    var maximum: CGFloat = 560
    var spacing: CGFloat = .RinkSpace.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimum, maximum: maximum), spacing: spacing)],
            alignment: .leading,
            spacing: spacing,
            content: content
        )
    }
}

#Preview("Adaptive grid") {
    ScrollView {
        RinkAdaptiveGrid {
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Rink.frostWash)
                    .frame(height: 120)
                    .overlay(Text("Card \(i + 1)").font(.rinkCardTitle))
            }
        }
        .padding()
    }
    .background(Rink.canvas)
}
