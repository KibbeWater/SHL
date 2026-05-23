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
    public var teamObj: Team?

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
        case 2: return Color(uiColor: .systemGray2)
        case 3: return .orange
        default: return .secondary
        }
    }

    private var medalSymbol: String? {
        switch standing.position {
        case 1: return "trophy.fill"
        case 2, 3: return "medal.fill"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Position with medal icon for top 3
            ZStack {
                Text("\(standing.position)")
                    .font(.footnote.weight(isTopThree ? .bold : .semibold))
                    .foregroundStyle(isTopThree ? positionColor : .secondary)
                    .monospacedDigit()
            }
            .frame(width: 20, alignment: .center)

            // Team logo
            TeamLogoView(teamCode: standing.teamCode, size: .custom(28))
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)

            // Team name
            Text(standing.team)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            // Stats
            HStack(spacing: 12) {
                Text(standing.record)
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: standing.hasRecord ? 80 : 28, alignment: .center)

                Text(standing.diff)
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(standing.diff.hasPrefix("-") ? .red : (standing.diff == "0" ? .secondary : .green))
                    .frame(width: 32, alignment: .center)

                Text(standing.points)
                    .font(.callout.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(width: 32, alignment: .center)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if isFavorite {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.18),
                                    Color.accentColor.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.6),
                                    Color.accentColor.opacity(0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                    HStack {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: 3)
                            .padding(.vertical, 6)
                        Spacer()
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .animation(.smooth, value: isFavorite)
    }
}

private struct StandingsHeaderRow: View {
    let hasRecord: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("#")
                .frame(width: 20, alignment: .center)

            Color.clear
                .frame(width: 28)

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
        .font(.caption2.weight(.medium))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private struct PlayoffDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0), .yellow.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 9))
                    .symbolRenderingMode(.hierarchical)
                Text("PLAYOFFS")
                    .font(.caption2.weight(.bold))
                    .kerning(1.2)
            }
            .foregroundStyle(.yellow)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.yellow.opacity(0.14))
            )
            .overlay(Capsule().strokeBorder(.yellow.opacity(0.25), lineWidth: 0.5))

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
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                if let favoriteTeamId,
                   let favorite = items.first(where: { $0.teamId == favoriteTeamId }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text("#\(favorite.position)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: .capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(height: 0.5)

            StandingsHeaderRow(hasRecord: items.first?.hasRecord ?? false)

            Rectangle()
                .fill(.secondary.opacity(0.1))
                .frame(height: 0.5)

            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Group {
                        if let team = item.teamObj {
                            NavigationLink {
                                TeamView(team: team)
                            } label: {
                                StandingRowView(
                                    standing: item,
                                    isTopThree: item.position <= 3,
                                    isFavorite: item.teamId == favoriteTeamId
                                )
                            }
                            .buttonStyle(.scalePress)
                        } else {
                            StandingRowView(
                                standing: item,
                                isTopThree: item.position <= 3,
                                isFavorite: item.teamId == favoriteTeamId
                            )
                        }
                    }

                    if item.position == playoffCutoff && index < items.count - 1 {
                        PlayoffDivider()
                    } else if index < items.count - 1 {
                        Rectangle()
                            .fill(.secondary.opacity(0.08))
                            .frame(height: 0.5)
                            .padding(.leading, 50)
                    }
                }
            }
        }
    }
}

private var standingsSampleItems: [StandingObj] {
    [
        StandingObj(id: "1", teamId: "t1", position: 1, team: "Luleå Hockey", teamCode: "LHF", gamesPlayed: 52, wins: 30, overtimeWins: 6, losses: 10, overtimeLosses: 6, diff: "+61", points: "108"),
        StandingObj(id: "2", teamId: "t2", position: 2, team: "Frölunda HC", teamCode: "FHC", gamesPlayed: 52, wins: 26, overtimeWins: 8, losses: 12, overtimeLosses: 6, diff: "+38", points: "98"),
        StandingObj(id: "3", teamId: "t3", position: 3, team: "Skellefteå AIK", teamCode: "SKE", gamesPlayed: 52, wins: 24, overtimeWins: 6, losses: 16, overtimeLosses: 6, diff: "+22", points: "90"),
        StandingObj(id: "4", teamId: "t4", position: 4, team: "Färjestad BK", teamCode: "FBK", gamesPlayed: 52, wins: 22, overtimeWins: 5, losses: 18, overtimeLosses: 7, diff: "+15", points: "83"),
        StandingObj(id: "5", teamId: "t5", position: 5, team: "Rögle BK", teamCode: "RBK", gamesPlayed: 52, wins: 20, overtimeWins: 4, losses: 20, overtimeLosses: 8, diff: "+8", points: "76"),
        StandingObj(id: "6", teamId: "t6", position: 6, team: "Växjö Lakers", teamCode: "VLH", gamesPlayed: 52, wins: 18, overtimeWins: 5, losses: 22, overtimeLosses: 7, diff: "0", points: "71"),
        StandingObj(id: "7", teamId: "t7", position: 7, team: "IK Oskarshamn", teamCode: "IKO", gamesPlayed: 52, wins: 14, overtimeWins: 3, losses: 28, overtimeLosses: 7, diff: "-12", points: "55"),
    ]
}

#Preview {
    ScrollView {
        StandingsTable(
            title: "SHL 2024/25",
            items: standingsSampleItems,
            favoriteTeamId: "t3"
        )
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
        .padding()
    }
}

#Preview("Dark") {
    ScrollView {
        StandingsTable(
            title: "SHL 2024/25",
            items: standingsSampleItems,
            favoriteTeamId: "t3"
        )
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
        .padding()
    }
    .preferredColorScheme(.dark)
}
