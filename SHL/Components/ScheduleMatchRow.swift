//
//  ScheduleMatchRow.swift
//  SHL
//
//  A richer schedule row than the compact card: full team names stacked with the
//  winner emphasized (loser dimmed) on finished games, scores or kickoff time,
//  and a status + venue footer. Games involving the user's favorite team get a
//  colored accent bar so they stand out as you scan.
//

import SwiftUI

struct ScheduleMatchRow: View {
    let match: Match
    var live: LiveMatch?
    var favoriteCode: String? = nil

    @State private var favColor: Color = Rink.ice

    private var homeScore: Int { live?.homeScore ?? match.homeScore }
    private var awayScore: Int { live?.awayScore ?? match.awayScore }

    private var isLive: Bool {
        if let live { return live.gameState == .ongoing || live.gameState == .paused }
        return match.isLive()
    }
    private var isCancelled: Bool { match.isCancelled }
    private var isFinal: Bool { match.played }
    private var isUpcoming: Bool { !match.concluded && !isLive }

    private var homeWon: Bool { isFinal && homeScore > awayScore }
    private var awayWon: Bool { isFinal && awayScore > homeScore }

    private var involvesFavorite: Bool {
        guard let fav = favoriteCode?.uppercased() else { return false }
        return match.homeTeam.code.uppercased() == fav || match.awayTeam.code.uppercased() == fav
    }

    var body: some View {
        HStack(spacing: 0) {
            if involvesFavorite {
                RoundedRectangle(cornerRadius: 2)
                    .fill(favColor)
                    .frame(width: 3)
                    .padding(.vertical, 12)
                    .padding(.leading, 6)
            }
            VStack(spacing: .RinkSpace.sm) {
                teamLine(code: match.homeTeam.code, name: match.homeTeam.name,
                         score: homeScore, won: homeWon, dimmed: awayWon)
                teamLine(code: match.awayTeam.code, name: match.awayTeam.name,
                         score: awayScore, won: awayWon, dimmed: homeWon)
                footer
            }
            .padding(.horizontal, .RinkSpace.md)
            .padding(.vertical, .RinkSpace.md)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .saturation(isCancelled ? 0 : 1)
        .opacity(isCancelled ? 0.6 : 1)
        .onAppear {
            if let fav = favoriteCode, involvesFavorite {
                getCodeColor(teamKey: "Team/\(fav.uppercased())") { favColor = $0 }
            }
        }
    }

    private func teamLine(code: String, name: String, score: Int, won: Bool, dimmed: Bool) -> some View {
        HStack(spacing: .RinkSpace.sm) {
            TeamLogoView(teamCode: code, size: .custom(28))
            Text(name)
                .font(.subheadline.weight(won ? .bold : (isUpcoming || isLive ? .semibold : .medium)))
                .foregroundStyle(dimmed ? Color.secondary : Color.primary)
                .lineLimit(1)
            Spacer(minLength: .RinkSpace.sm)
            if !isUpcoming {
                Text("\(score)")
                    .font(.title3.weight(won ? .bold : .semibold).monospacedDigit())
                    .foregroundStyle(dimmed ? Color.secondary : Color.primary)
                    .frame(minWidth: 18, alignment: .trailing)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: .RinkSpace.sm) {
            statusLabel
            Spacer(minLength: .RinkSpace.sm)
            if let venue = match.venue, !venue.isEmpty {
                Label(venue, systemImage: "mappin.and.ellipse")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if isLive {
            HStack(spacing: .RinkSpace.xs) {
                RinkLiveBadge(compact: true)
                if let live {
                    Text(live.gameState == .paused ? String(localized: "Intermission") : "P\(live.period) · \(live.periodTime)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        } else if isCancelled {
            Text("CANCELLED").font(.caption2.weight(.bold)).tracking(0.5).foregroundStyle(.secondary)
        } else if isFinal {
            HStack(spacing: 4) {
                Text("FINAL").font(.caption2.weight(.bold)).tracking(0.5).foregroundStyle(.secondary)
                if match.overtime ?? false {
                    Text("· OT").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
                } else if match.shootout ?? false {
                    Text("· SO").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
                }
            }
        } else {
            Label("\(match.formatDate()) · \(match.formatTime())", systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Schedule rows") {
    ScrollView {
        VStack(spacing: 8) {
            ScheduleMatchRow(match: Match.fakeData(), favoriteCode: "FHC")     // final, OT
            ScheduleMatchRow(match: .init(id: "u", date: Date().addingTimeInterval(90000), venue: "Frölundaborg",
                                          homeTeam: .init(id: "1", name: "Frölunda HC", code: "FHC"),
                                          awayTeam: .init(id: "2", name: "Färjestad BK", code: "FBK"),
                                          homeScore: 0, awayScore: 0, state: .scheduled, overtime: false, shootout: false, externalUUID: "u"),
                             favoriteCode: "FHC")
            ScheduleMatchRow(match: Match.cancelledFakeData())
        }
        .padding()
    }
    .background(RinkAmbientBackground(.arena))
}

#Preview("Schedule rows · Dark") {
    ScrollView {
        VStack(spacing: 8) {
            ScheduleMatchRow(match: Match.fakeData(), favoriteCode: "IKO")
            ScheduleMatchRow(match: .init(id: "u", date: Date().addingTimeInterval(90000), venue: "Coop Arena",
                                          homeTeam: .init(id: "1", name: "Luleå HF", code: "LHF"),
                                          awayTeam: .init(id: "2", name: "Skellefteå AIK", code: "SAIK"),
                                          homeScore: 0, awayScore: 0, state: .scheduled, overtime: false, shootout: false, externalUUID: "u"))
        }
        .padding()
    }
    .background(RinkAmbientBackground(.arena))
    .preferredColorScheme(.dark)
}
