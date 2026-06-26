//
//  InterestedTeamRows.swift
//  SHL
//
//  Created by Claude Code
//

import SwiftUI

/// A small uppercase pill showing a team's code (e.g. "LHF").
struct TeamCodeBadge: View {
    let code: String

    var body: some View {
        Text(code.uppercased())
            .font(.caption2.weight(.semibold))
            .monospaced()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.quaternary, in: .capsule)
    }
}

/// Hero row for the user's favorite team, subtly tinted with the team's colour.
/// Designed to sit as a row inside an inset-grouped `List`/`Form` section.
struct FavoriteTeamRow: View {
    let name: String
    let code: String
    let city: String?
    let iconURL: String?
    var onTap: () -> Void

    @State private var accent: Color = .gray

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                TeamLogoView(teamCode: code, iconURL: iconURL, size: .custom(44))
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Label("Favorite", systemImage: "star.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.yellow)
                        .textCase(.uppercase)

                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let city, !city.isEmpty {
                        Text(city)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            ZStack {
                Color(.secondarySystemGroupedBackground)
                LinearGradient(
                    colors: [accent.opacity(0.30), accent.opacity(0.07), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .task {
            getCodeColor(teamKey: "Team/\(code.uppercased())") { color in
                withAnimation(.smooth) { accent = color }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Favorite team, \(name)")
        .accessibilityHint("Opens the favorite team picker")
    }
}

/// Compact row for a followed (non-favorite) team.
struct InterestedTeamRow: View {
    let name: String
    let code: String
    let iconURL: String?

    var body: some View {
        HStack(spacing: 12) {
            TeamLogoView(teamCode: code, iconURL: iconURL, size: .custom(30))
                .frame(width: 32, height: 32)

            Text(name)
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            TeamCodeBadge(code: code)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
    }
}

#Preview {
    List {
        Section {
            FavoriteTeamRow(
                name: "Luleå HF",
                code: "LHF",
                city: "Luleå",
                iconURL: nil,
                onTap: {}
            )
            InterestedTeamRow(name: "Frölunda HC", code: "FHC", iconURL: nil)
            InterestedTeamRow(name: "Skellefteå AIK", code: "SKE", iconURL: nil)
        } header: {
            Text("Interested Teams")
        }
    }
}
