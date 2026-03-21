//
//  StandingsTable.swift
//  SHL
//
//  League standings table component
//

import SwiftUI

struct StandingObj: Identifiable, Equatable {
    public var id: String
    public var teamId: String
    public var position: Int
    public var team: String
    public var teamCode: String
    public var gamesPlayed: Int
    public var wins: Int?
    public var overtimeWins: Int?
    public var losses: Int?
    public var overtimeLosses: Int?
    public var diff: String
    public var points: String

    var hasRecord: Bool {
        wins != nil && losses != nil && overtimeLosses != nil && overtimeWins != nil
    }

    var record: String {
        if let w = wins, let otw = overtimeWins, let otl = overtimeLosses, let l = losses {
            return "\(w)-\(otw)-\(otl)-\(l)"
        }
        return "\(gamesPlayed)"
    }
}

struct StandingRowView: View {
    let standing: StandingObj
    let isTopThree: Bool
    let isFavorite: Bool

    private var positionColor: Color {
        switch standing.position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Position
            Text("\(standing.position)")
                .font(.system(size: 14, weight: isTopThree ? .bold : .semibold, design: .rounded))
                .foregroundStyle(isTopThree ? positionColor : .secondary)
                .frame(width: 20, alignment: .center)

            // Team logo
            TeamLogoView(teamCode: standing.teamCode, size: .custom(26))

            // Team name
            Text(standing.team)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Stats
            HStack(spacing: 12) {
                // W-L-OTL record or GP
                Text(standing.record)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: standing.hasRecord ? 80 : 28, alignment: .center)

                // Goal difference
                Text(standing.diff)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(standing.diff.hasPrefix("-") ? .red : (standing.diff == "0" ? .secondary : .green))
                    .frame(width: 32, alignment: .center)

                // Points
                Text(standing.points)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(width: 32, alignment: .center)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if isFavorite {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.15),
                                    Color.accentColor.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.5),
                                    Color.accentColor.opacity(0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                    // Leading accent bar
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 3)
                            .padding(.vertical, 6)
                        Spacer()
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

private struct StandingsHeaderRow: View {
    let hasRecord: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Position
            Text("#")
                .frame(width: 20, alignment: .center)

            // Spacer for logo (26) + gap
            Color.clear
                .frame(width: 26)

            Text("Team")
            Spacer()

            HStack(spacing: 12) {
                Text(hasRecord ? "W-OTW-OTL-L" : "GP")
                    .frame(width: hasRecord ? 80 : 28, alignment: .center)
                Text("GD")
                    .frame(width: 32, alignment: .center)
                Text("PTS")
                    .frame(width: 32, alignment: .center)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private struct PlayoffDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            // Left line with gradient fade-in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0), .yellow.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            // Label
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 8))
                Text("PLAYOFFS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .kerning(1.2)
            }
            .foregroundStyle(.yellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.yellow.opacity(0.12))
            )

            // Right line with gradient fade-out
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0.5), .yellow.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct StandingsTable: View {
    public var title: String
    public var items: [StandingObj]
    public var favoriteTeamId: String? = nil
    public var onRefresh: (() async -> Void)? = nil

    private let playoffCutoff = 6

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Divider
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(height: 1)

            // Column headers
            StandingsHeaderRow(hasRecord: items.first?.hasRecord ?? false)

            Rectangle()
                .fill(.secondary.opacity(0.1))
                .frame(height: 1)

            // Rows
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    StandingRowView(
                        standing: item,
                        isTopThree: item.position <= 3,
                        isFavorite: item.teamId == favoriteTeamId
                    )

                    if item.position == playoffCutoff && index < items.count - 1 {
                        PlayoffDivider()
                    } else if index < items.count - 1 {
                        Rectangle()
                            .fill(.secondary.opacity(0.1))
                            .frame(height: 1)
                            .padding(.leading, 48)
                    }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        StandingsTable(
            title: "SHL 2024/25",
            items: [
                StandingObj(id: "1", teamId: "t1", position: 1, team: "Luleå Hockey", teamCode: "LHF", gamesPlayed: 52, wins: 30, overtimeWins: 6, losses: 10, overtimeLosses: 6, diff: "+61", points: "108"),
                StandingObj(id: "2", teamId: "t2", position: 2, team: "Frölunda HC", teamCode: "FHC", gamesPlayed: 52, wins: 26, overtimeWins: 8, losses: 12, overtimeLosses: 6, diff: "+38", points: "98"),
                StandingObj(id: "3", teamId: "t3", position: 3, team: "Skellefteå AIK", teamCode: "SKE", gamesPlayed: 52, wins: 24, overtimeWins: 6, losses: 16, overtimeLosses: 6, diff: "+22", points: "90"),
                StandingObj(id: "4", teamId: "t4", position: 4, team: "Färjestad BK", teamCode: "FBK", gamesPlayed: 52, wins: 22, overtimeWins: 5, losses: 18, overtimeLosses: 7, diff: "+15", points: "83"),
                StandingObj(id: "5", teamId: "t5", position: 5, team: "Rögle BK", teamCode: "RBK", gamesPlayed: 52, wins: 20, overtimeWins: 4, losses: 20, overtimeLosses: 8, diff: "+8", points: "76"),
                StandingObj(id: "6", teamId: "t6", position: 6, team: "Växjö Lakers", teamCode: "VLH", gamesPlayed: 52, wins: 18, overtimeWins: 5, losses: 22, overtimeLosses: 7, diff: "0", points: "71"),
                StandingObj(id: "7", teamId: "t7", position: 7, team: "IK Oskarshamn", teamCode: "IKO", gamesPlayed: 52, wins: 14, overtimeWins: 3, losses: 28, overtimeLosses: 7, diff: "-12", points: "55"),
            ],
            favoriteTeamId: "t3"
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}
