//
//  HomeFeedSections.swift
//  SHL
//
//  The building blocks of the redesigned home feed, drawn with the Rink design
//  system: a time-aware greeting, the bold favorite-team hero, the featured
//  matchup, the compact live card, and a stat leaderboard card. Cards are
//  flexible-width so the feed can reflow them into adaptive grids and carousels.
//

import SwiftUI

// MARK: - Mapping helpers

extension FormOutcome {
    /// The presentation pip color for this result.
    var pip: RinkFormResult {
        switch self {
        case .win: return .win
        case .otWin: return .otWin
        case .otLoss: return .otLoss
        case .loss: return .loss
        }
    }
}

private func ordinal(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .ordinal
    f.locale = .current
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

/// A 1-pt hairline that reads consistently in light and dark.
private var rinkHairline: some View {
    Rectangle().fill(Color.primary.opacity(0.08))
}

// MARK: - Greeting

struct HomeGreetingHeader: View {
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return String(localized: "Good morning")
        case 12..<17: return String(localized: "Good afternoon")
        case 17..<22: return String(localized: "Good evening")
        default:      return String(localized: "Late-night hockey")
        }
    }

    private var dateText: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SHL").rinkKicker(Rink.ice)
            Text(greeting).font(.rinkTitle)
            Text(dateText).font(.rinkCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Favorite team hero

/// The bold, branded anchor of the page. An immersive card washed in the team's
/// own color, with a faint oversized logo watermark, the standing + form laid
/// out horizontally, and a tappable "next game" footer. Because it's the only
/// strongly-colored surface on the screen, it reads as a focal point — not noise.
struct FavoriteSpotlightCard: View {
    let favorite: FavoriteTeamSummary
    /// Full team for navigation (resolved from standings); falls back gracefully.
    let team: Team?

    @State private var teamColor: Color = Rink.ice

    private var pips: [RinkFormResult] { favorite.form.map(\.pip) }

    var body: some View {
        VStack(spacing: 0) {
            identity
            if let next = favorite.nextMatch {
                nextFooter(next)
            }
        }
        .background { background }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .rinkCardLift(radius: 16)
        .onAppear { getCodeColor(teamKey: "Team/\(favorite.team.code.uppercased())") { teamColor = $0 } }
    }

    // Identity + standing. Taps through to the team page when we have the full team
    // (resolved from standings); otherwise it stays a plain, full-opacity panel —
    // never a dimmed, disabled button (which greys out the white type).
    @ViewBuilder
    private var identity: some View {
        if let team {
            NavigationLink { TeamView(team: team) } label: { identityContent }
                .buttonStyle(.plain)
        } else {
            identityContent
        }
    }

    private var identityContent: some View {
        VStack(alignment: .leading, spacing: .RinkSpace.lg) {
            HStack(alignment: .top) {
                Label("Your Team", systemImage: "star.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                if let rank = favorite.rank {
                    Text(ordinal(rank))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.white)
                }
            }

            HStack(alignment: .center, spacing: .RinkSpace.md) {
                TeamLogoView(teamCode: favorite.team.code, size: .custom(50))
                    .padding(7)
                    .background(.white.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(favorite.team.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: .RinkSpace.md) {
                        if let pts = favorite.points {
                            Text("\(pts) PTS")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        if !pips.isEmpty {
                            RinkFormPips(results: pips, size: 8)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.RinkSpace.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    // Next game — a translucent footer bar that taps through to the match.
    private func nextFooter(_ match: Match) -> some View {
        NavigationLink {
            MatchView(match, referrer: "home_favorite")
        } label: {
            HStack(spacing: .RinkSpace.sm) {
                Text("NEXT")
                    .font(.caption2.weight(.bold)).tracking(1.0)
                    .foregroundStyle(.white.opacity(0.65))
                opponentLabel(for: match, on: .white)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: .RinkSpace.sm)
                Text("\(match.formatDate()) · \(match.formatTime())")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, .RinkSpace.lg)
            .padding(.vertical, .RinkSpace.md)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.22))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [teamColor.darkened(by: 0.16), teamColor.darkened(by: 0.52)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            // Faint oversized logo watermark bleeding off the trailing edge.
            TeamLogoView(teamCode: favorite.team.code, size: .custom(210))
                .opacity(0.12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 64)
                .allowsHitTesting(false)
        }
    }

    /// "vs LHF" / "@ FBK" relative to the favorite team, in the given foreground.
    private func opponentLabel(for match: Match, on color: Color) -> Text {
        let favCode = favorite.team.code.uppercased()
        let isHome = match.homeTeam.code.uppercased() == favCode
        let opponent = isHome ? match.awayTeam.code : match.homeTeam.code
        return Text(isHome ? "vs " : "@ ").foregroundColor(color.opacity(0.7)) + Text(opponent).foregroundColor(color)
    }
}

// MARK: - Featured hero

/// The big, full-width matchup — a darkened two-team "split gradient" (home
/// color bleeding in from the left, away from the right, deepest in the middle
/// where the score sits) with white type. Bold and branded, matching the
/// favorite-team hero.
struct FeaturedHeroCard: View {
    let match: Match
    var live: LiveMatch?

    @State private var homeColor: Color = Rink.steel
    @State private var awayColor: Color = Rink.steel

    private var homeScore: Int { live?.homeScore ?? match.homeScore }
    private var awayScore: Int { live?.awayScore ?? match.awayScore }
    private var isLive: Bool {
        if let live { return live.gameState == .ongoing || live.gameState == .paused }
        return match.isLive()
    }

    var body: some View {
        VStack(spacing: .RinkSpace.lg) {
            statusBar
            HStack(alignment: .center, spacing: .RinkSpace.sm) {
                teamColumn(code: match.homeTeam.code, name: match.homeTeam.name)
                scoreBlock
                teamColumn(code: match.awayTeam.code, name: match.awayTeam.name)
            }
        }
        .padding(.RinkSpace.xl)
        .frame(maxWidth: .infinity)
        .background { background }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .rinkCardLift(radius: 18)
        .onAppear {
            getCodeColor(teamKey: "Team/\(match.homeTeam.code.uppercased())") { homeColor = $0 }
            getCodeColor(teamKey: "Team/\(match.awayTeam.code.uppercased())") { awayColor = $0 }
        }
        .accessibilityElement(children: .combine)
    }

    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return shape
            .fill(LinearGradient(stops: [
                .init(color: homeColor.darkened(by: 0.24), location: 0.0),
                .init(color: homeColor.darkened(by: 0.54), location: 0.40),
                .init(color: awayColor.darkened(by: 0.54), location: 0.60),
                .init(color: awayColor.darkened(by: 0.24), location: 1.0)
            ], startPoint: .leading, endPoint: .trailing))
            .overlay(shape.stroke(isLive ? Rink.goal.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 1))
    }

    private var statusBar: some View {
        HStack {
            if isLive {
                RinkLiveBadge()
                if let live {
                    Text(live.gameState == .paused ? String(localized: "Intermission") : "P\(live.period) · \(live.periodTime)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else if match.concluded {
                Text(match.isCancelled ? "CANCELLED" : "FINAL")
                    .font(.caption2.weight(.bold)).tracking(1)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Label("\(match.formatDate()) · \(match.formatTime())", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            if let venue = match.venue {
                Label(venue, systemImage: "mappin.and.ellipse")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private func teamColumn(code: String, name: String) -> some View {
        VStack(spacing: .RinkSpace.sm) {
            TeamLogoView(teamCode: code, size: .custom(60))
            Text(code).font(.headline.weight(.bold)).foregroundStyle(.white)
            Text(name).font(.caption2).foregroundStyle(.white.opacity(0.65)).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var scoreBlock: some View {
        VStack(spacing: 2) {
            if match.concluded || isLive {
                HStack(spacing: .RinkSpace.sm) {
                    Text("\(homeScore)").font(.rinkScore)
                    Text("–").font(.rinkScore).foregroundStyle(.white.opacity(0.5))
                    Text("\(awayScore)").font(.rinkScore)
                }
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                if match.overtime ?? false {
                    Text("OT").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.7))
                } else if match.shootout ?? false {
                    Text("SO").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text("VS").font(.rinkTitle).foregroundStyle(.white.opacity(0.8))
            }
        }
        .fixedSize()
        .animation(.snappy, value: homeScore)
        .animation(.snappy, value: awayScore)
    }
}

// MARK: - Live card

/// A compact live game — a smaller, darker sibling of the featured hero: a
/// team-color split gradient with white type and the pulsing LIVE lamp.
/// Flexible width so the feed can place it full-width or two-up in a grid.
struct LiveGameCard: View {
    let match: Match
    var live: LiveMatch?

    @State private var homeColor: Color = Rink.steel
    @State private var awayColor: Color = Rink.steel

    private var homeScore: Int { live?.homeScore ?? match.homeScore }
    private var awayScore: Int { live?.awayScore ?? match.awayScore }

    var body: some View {
        VStack(alignment: .leading, spacing: .RinkSpace.sm) {
            HStack(spacing: .RinkSpace.xs) {
                RinkLiveBadge(compact: true)
                if let live {
                    Text(live.gameState == .paused ? String(localized: "Int.") : "P\(live.period) · \(live.periodTime)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }
            teamLine(code: match.homeTeam.code, score: homeScore)
            teamLine(code: match.awayTeam.code, score: awayScore)
        }
        .padding(.RinkSpace.md)
        .frame(maxWidth: .infinity)
        .background { background }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear {
            getCodeColor(teamKey: "Team/\(match.homeTeam.code.uppercased())") { homeColor = $0 }
            getCodeColor(teamKey: "Team/\(match.awayTeam.code.uppercased())") { awayColor = $0 }
        }
    }

    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [homeColor.darkened(by: 0.42), awayColor.darkened(by: 0.42)],
                                 startPoint: .leading, endPoint: .trailing))
            .overlay(shape.stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func teamLine(code: String, score: Int) -> some View {
        HStack(spacing: .RinkSpace.sm) {
            TeamLogoView(teamCode: code, size: .custom(24))
            Text(code).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
            Spacer()
            Text("\(score)").font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(.white)
        }
    }
}

// MARK: - Leaderboard card

/// One stat leaderboard (Points / Goals / Save %) — title + top three. Flexible
/// width so it reflows in the leaders carousel.
struct LeaderBoardCard: View {
    let board: LeaderBoard

    private func icon(for id: String) -> String {
        switch id {
        case "points": return "chart.bar.fill"
        case "goals": return "hockey.puck.fill"
        case "assists": return "arrow.up.forward"
        case "save_pct", "saves": return "shield.lefthalf.filled"
        default: return "rosette"
        }
    }

    var body: some View {
        RinkCard(.frost, padding: .RinkSpace.md) {
            VStack(alignment: .leading, spacing: .RinkSpace.sm) {
                Label(board.title, systemImage: icon(for: board.id))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Rink.ice)
                rinkHairline.frame(height: 1).opacity(0.6)
                ForEach(Array(board.entries.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                    row(rank: idx + 1, entry: entry)
                }
            }
        }
    }

    private func row(rank: Int, entry: LeaderEntry) -> some View {
        HStack(spacing: .RinkSpace.sm) {
            Text("\(rank)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(rank == 1 ? Rink.gold : .secondary)
                .frame(width: 14)
            TeamLogoView(teamCode: entry.teamCode, size: .custom(20))
            Text(entry.playerName)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: .RinkSpace.xs)
            Text(entry.display)
                .font(.subheadline.weight(.bold).monospacedDigit())
        }
    }
}

// MARK: - Pre-season hero

/// Counts down to opening night — the focal point of the pre-season home. Cool,
/// anticipatory brand wash with an oversized puck watermark, matching the favorite
/// and featured heroes so all three home variants feel like one family.
struct PreseasonHeroCard: View {
    let openingDate: Date
    var seasonName: String? = nil

    private var daysAway: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: Date())
        let to = cal.startOfDay(for: openingDate)
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    private var bigLine: String {
        switch daysAway {
        case 0: return String(localized: "Tonight")
        case 1: return String(localized: "Tomorrow")
        default: return "\(daysAway)"
        }
    }

    private var subLine: String {
        daysAway <= 1 ? String(localized: "Opening night")
                      : String(localized: "days until opening night")
    }

    private var dateText: String {
        openingDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .RinkSpace.sm) {
            HStack {
                Label("Season Starts", systemImage: "sparkles")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2.weight(.bold)).textCase(.uppercase).tracking(1.1)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                if let seasonName {
                    Text(seasonName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.bottom, .RinkSpace.xs)

            Text(bigLine)
                .font(.rinkDisplay)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(subLine)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            Label(dateText, systemImage: "calendar")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, .RinkSpace.xs)
        }
        .padding(.RinkSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { preseasonBackground }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .rinkCardLift(radius: 16)
        .accessibilityElement(children: .combine)
    }

    private var preseasonBackground: some View {
        ZStack {
            LinearGradient(colors: [Rink.ice.darkened(by: 0.18), Rink.glacier.darkened(by: 0.52)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "hockey.puck.fill")
                .font(.system(size: 190))
                .foregroundStyle(.white.opacity(0.07))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 50, y: 10)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Champion hero

/// Crowns the season's champion in a gold-accented, team-color celebration — the
/// anchor of the concluded-season home.
struct ChampionHeroCard: View {
    let champion: ChampionInfo
    var seasonName: String? = nil

    @State private var teamColor: Color = Rink.gold

    private var kicker: String {
        seasonName.map { "\($0) · \(champion.label)" } ?? champion.label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .RinkSpace.lg) {
            HStack(spacing: .RinkSpace.xs) {
                Image(systemName: "trophy.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Rink.gold)
                Text(kicker)
                    .font(.caption2.weight(.bold)).textCase(.uppercase).tracking(1.1)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }

            HStack(alignment: .center, spacing: .RinkSpace.md) {
                TeamLogoView(teamCode: champion.team.code, size: .custom(56))
                    .padding(8)
                    .background(.white.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(champion.team.name)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2).minimumScaleFactor(0.7)
                    Text("Champions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Rink.gold)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.RinkSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { championBackground }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .rinkCardLift(radius: 18)
        .onAppear {
            getCodeColor(teamKey: "Team/\(champion.team.code.uppercased())") { teamColor = $0 }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(champion.team.name), \(champion.label)")
    }

    private var championBackground: some View {
        ZStack {
            LinearGradient(colors: [teamColor.darkened(by: 0.14), teamColor.darkened(by: 0.56)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Rink.gold.opacity(0.32), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 280)
            TeamLogoView(teamCode: champion.team.code, size: .custom(210))
                .opacity(0.10)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 64)
                .allowsHitTesting(false)
        }
    }
}

/// The quiet "see you next season" note that closes the concluded-season home.
struct SeasonClosedNote: View {
    var body: some View {
        VStack(spacing: .RinkSpace.xs) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(Rink.ice)
            Text("Season Complete")
                .font(.headline)
            Text("Next season's schedule arrives soon — check back then.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .RinkSpace.xl)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("Season heroes · Dark") {
    ScrollView {
        VStack(spacing: 16) {
            PreseasonHeroCard(
                openingDate: Calendar.current.date(byAdding: .day, value: 84, to: Date()) ?? Date(),
                seasonName: "2026/27"
            )
            ChampionHeroCard(
                champion: ChampionInfo(
                    team: Team(id: "t-LHF", name: "Luleå HF", code: "LHF", city: nil, founded: nil,
                               venue: nil, golds: nil, goldYears: nil, finals: nil, finalYears: nil,
                               iconURL: nil, isActive: true),
                    label: "Champions"
                ),
                seasonName: "2025/26"
            )
            SeasonClosedNote()
        }
        .padding()
    }
    .background(RinkAmbientBackground(.arena))
    .preferredColorScheme(.dark)
}

#Preview("Favorite hero") {
    NavigationStack {
        ScrollView {
            VStack {
                FavoriteSpotlightCard(favorite: HomeSummary.mock.favorite!, team: nil)
            }
            .padding()
        }
        .background(RinkAmbientBackground(.team(Rink.ice)))
    }
}

#Preview("Favorite hero · Dark") {
    NavigationStack {
        ScrollView {
            FavoriteSpotlightCard(favorite: HomeSummary.mock.favorite!, team: nil)
                .padding()
        }
        .background(RinkAmbientBackground(.arena))
    }
    .preferredColorScheme(.dark)
}

#Preview("Featured + Live · Dark") {
    NavigationStack {
        VStack(spacing: 16) {
            FeaturedHeroCard(match: HomeSummary.mock.featured!, live: nil)
            LiveGameCard(match: HomeSummary.mock.live[1], live: nil)
            LeaderBoardCard(board: HomeSummary.mock.leaders!.boards[0])
        }
        .padding()
        .background(RinkAmbientBackground(.arena))
    }
    .preferredColorScheme(.dark)
}
