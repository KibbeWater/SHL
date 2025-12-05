//
//  StandingsTable.swift
//  SHL
//
//  League standings table component
//

import SwiftUI

struct StandingObj: Identifiable, Equatable {
    public var id: String
    public var position: Int
    public var team: String
    public var teamCode: String
    public var matches: String
    public var diff: String
    public var points: String
}

struct StandingRowView: View {
    let standing: StandingObj
    let isTopThree: Bool

    private var positionColor: Color {
        switch standing.position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Position
            Text("\(standing.position)")
                .font(.system(size: 15, weight: isTopThree ? .bold : .semibold, design: .rounded))
                .foregroundStyle(isTopThree ? positionColor : .secondary)
                .frame(width: 24, alignment: .center)

            // Team logo
            TeamLogoView(teamCode: standing.teamCode, size: .custom(32))

            // Team name
            Text(standing.team)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Stats
            HStack(spacing: 16) {
                // Games played
                VStack(spacing: 1) {
                    Text(standing.matches)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("GP")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 28)

                // Goal difference
                VStack(spacing: 1) {
                    Text(standing.diff)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(standing.diff.hasPrefix("-") ? .red : (standing.diff == "0" ? .secondary : .green))
                    Text("GD")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 32)

                // Points
                VStack(spacing: 1) {
                    Text(standing.points)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("PTS")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct StandingsTable: View {
    public var title: String
    public var items: [StandingObj]
    public var onRefresh: (() async -> Void)? = nil

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

            // Rows
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    StandingRowView(
                        standing: item,
                        isTopThree: item.position <= 3
                    )

                    if index < items.count - 1 {
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
                StandingObj(id: "1", position: 1, team: "Luleå Hockey", teamCode: "LHF", matches: "32", diff: "+45", points: "72"),
                StandingObj(id: "2", position: 2, team: "Frölunda HC", teamCode: "FHC", matches: "32", diff: "+38", points: "68"),
                StandingObj(id: "3", position: 3, team: "Skellefteå AIK", teamCode: "SKE", matches: "32", diff: "+22", points: "61"),
                StandingObj(id: "4", position: 4, team: "Färjestad BK", teamCode: "FBK", matches: "32", diff: "+15", points: "58"),
                StandingObj(id: "5", position: 5, team: "Rögle BK", teamCode: "RBK", matches: "32", diff: "+8", points: "54"),
                StandingObj(id: "6", position: 6, team: "Växjö Lakers", teamCode: "VLH", matches: "32", diff: "0", points: "48"),
                StandingObj(id: "7", position: 7, team: "IK Oskarshamn", teamCode: "IKO", matches: "32", diff: "-12", points: "42"),
            ]
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}
