//
//  RinkSectionHeader.swift
//  SHL
//
//  The label that sits above each home-feed section: a tinted SF Symbol, a bold
//  title, an optional subtitle, and an optional trailing affordance (usually a
//  "See All" link into the relevant tab).
//

import SwiftUI

struct RinkSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconTint: Color = Rink.ice
    var trailing: AnyView? = nil

    init(_ title: String, subtitle: String? = nil, icon: String? = nil, iconTint: Color = Rink.ice) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconTint = iconTint
    }

    init<Trailing: View>(_ title: String, subtitle: String? = nil, icon: String? = nil,
                         iconTint: Color = Rink.ice, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconTint = iconTint
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .center, spacing: .RinkSpace.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.headline)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconTint)
                    .frame(width: 26)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.rinkTitle)
                if let subtitle {
                    Text(subtitle).font(.rinkCaption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: .RinkSpace.sm)
            if let trailing { trailing }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A standard "See All ›" trailing link for section headers, tinted to the brand.
struct RinkSeeAll: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text("See All")
                Image(systemName: "chevron.right").font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
        }
        .tint(Rink.ice)
        .accessibilityLabel("See all")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 28) {
        RinkSectionHeader("Live Now", subtitle: "3 games in progress", icon: "dot.radiowaves.left.and.right", iconTint: Rink.goal)
        RinkSectionHeader("Upcoming", icon: "calendar") {
            RinkSeeAll {}
        }
        RinkSectionHeader("League Leaders", subtitle: "Points", icon: "chart.bar.fill", iconTint: Rink.gold)
    }
    .padding()
    .background(Rink.canvas)
}
