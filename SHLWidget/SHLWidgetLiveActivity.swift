//
//  SHLWidgetLiveActivity.swift
//  SHLWidget
//
//  Created by user242911 on 1/4/24.
//  Redesigned for enhanced visual experience
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Helper Extensions

extension AnyTransition {
    static var moveDown: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top),
            removal: .move(edge: .bottom)
        )
    }
}

// MARK: - Team Colors (using shared TeamColorCache)

// MARK: - Shared Helper Views

private struct LiveIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(.red)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.7 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

private struct StatusBadge: View {
    let state: SHLWidgetAttributes.ActivityState
    let period: Int

    var body: some View {
        HStack(spacing: 6) {
            switch state {
            case .ongoing, .overtime:
                LiveIndicator()
                Text(state == .overtime ? "OT" : "LIVE")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .textCase(.uppercase)
            case .onbreak, .intermission:
                Image(systemName: "pause.circle.fill")
                    .font(.caption2)
                Text("INT")
                    .font(.caption2)
                    .fontWeight(.bold)
            case .ended:
                Text("FINAL")
                    .font(.caption2)
                    .fontWeight(.bold)
            case .starting:
                Image(systemName: "clock")
                    .font(.caption2)
                Text("SOON")
                    .font(.caption2)
                    .fontWeight(.bold)
            }

            if state != .ended {
                Text("P\(period)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(Capsule())
    }
}

private struct ScoreText: View {
    let score: Int
    let isLeading: Bool
    let size: CGFloat

    var body: some View {
        Text(String(score))
            .font(.system(size: size, weight: .bold, design: .rounded))
            .fontWidth(.compressed)
            .foregroundStyle(isLeading ? .primary : .secondary)
            .contentTransition(.numericText())
            .monospacedDigit()
    }
}

private struct TeamLogo: View {
    let teamCode: String
    let size: CGFloat

    var body: some View {
        Image("Team/\(teamCode)")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - Helper Functions

private func parseISODate(_ dateString: String) -> Date {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: dateString) ?? .distantFuture
}

private func cappedPeriodEnd(_ dateString: String) -> Date {
    let periodEnd = parseISODate(dateString)
    let maxEnd = Date.now.addingTimeInterval(1200) // Cap at 20:00
    return min(periodEnd, maxEnd)
}

// MARK: - Live Activity Widget

struct SHLWidgetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SHLWidgetAttributes.self) { context in
            // MARK: Lock Screen / Notification Center
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
            } compactLeading: {
                // MARK: Compact Leading
                CompactLeadingView(context: context)
            } compactTrailing: {
                // MARK: Compact Trailing
                CompactTrailingView(context: context)
            } minimal: {
                // MARK: Minimal
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "shltracker://open-game?id=\(context.attributes.internalId)"))
            .keylineTint(keylineColor(for: context))
        }
    }

    private func keylineColor(for context: ActivityViewContext<SHLWidgetAttributes>) -> Color {
        let homeScore = context.state.homeScore
        let awayScore = context.state.awayScore

        if homeScore > awayScore {
            return TeamColorCache.color(for: context.attributes.homeTeam.teamCode)
        } else if awayScore > homeScore {
            return TeamColorCache.color(for: context.attributes.awayTeam.teamCode)
        } else {
            return .white
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    private var homeCode: String { context.attributes.homeTeam.teamCode }
    private var awayCode: String { context.attributes.awayTeam.teamCode }
    private var homeScore: Int { context.state.homeScore }
    private var awayScore: Int { context.state.awayScore }
    private var gameState: SHLWidgetAttributes.ActivityState { context.state.period.state }
    private var period: Int { context.state.period.period }
    private var periodEnd: String { context.state.period.periodEnd }

    private var isLive: Bool {
        gameState == .ongoing || gameState == .overtime
    }

    private var homeColor: Color {
        TeamColorCache.color(for: homeCode)
    }

    private var awayColor: Color {
        TeamColorCache.color(for: awayCode)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Home team
            HStack(spacing: 10) {
                Image("Team/\(homeCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)

                if gameState == .intermission {
                    Text(homeCode)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("\(homeScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .fontWidth(.compressed)
                        .foregroundStyle(homeScore >= awayScore ? .white : .white.opacity(0.5))
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Center - Status & Timer (fixed width ensures true centering)
            VStack(spacing: 4) {
                if gameState == .intermission {
                    // Pre-game state
                    Text("VS")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Waiting for start")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                } else if gameState == .ended {
                    // Game ended state
                    Text("FINAL")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Game Ended")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    HStack(spacing: 4) {
                        if isLive {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        }
                        Text(statusText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    if isLive || gameState == .onbreak {
                        Text(cappedPeriodEnd(periodEnd), style: .timer)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(width: 100)

            // Away team
            HStack(spacing: 10) {
                if gameState == .intermission {
                    Text(awayCode)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("\(awayScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .fontWidth(.compressed)
                        .foregroundStyle(awayScore >= homeScore ? .white : .white.opacity(0.5))
                        .contentTransition(.numericText())
                }

                Image("Team/\(awayCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(white: 0.1))
        .activityBackgroundTint(Color(white: 0.1))
    }

    private var statusText: String {
        switch gameState {
        case .ongoing:
            return "LIVE • P\(period)"
        case .overtime:
            return "LIVE • OT"
        case .intermission:
            return "INT • P\(period)"
        case .onbreak:
            return "BREAK"
        case .ended:
            return "FINAL"
        case .starting:
            return "SOON"
        }
    }
}

// MARK: - Timer Display

private struct TimerDisplay: View {
    let state: SHLWidgetAttributes.ActivityState
    let periodEnd: String
    let period: Int
    let fontSize: Font.TextStyle

    var body: some View {
        switch state {
        case .ongoing, .overtime:
            Text(cappedPeriodEnd(periodEnd), style: .timer)
                .font(.system(fontSize == .largeTitle ? .largeTitle : .title))
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .monospacedDigit()
                .multilineTextAlignment(.center)
        case .onbreak:
            VStack(spacing: 2) {
                Text(cappedPeriodEnd(periodEnd), style: .timer)
                    .font(.system(fontSize == .largeTitle ? .title2 : .headline))
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .monospacedDigit()
                Text("BREAK")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
        case .intermission:
            VStack(spacing: 2) {
                Text("INT")
                    .font(.system(fontSize == .largeTitle ? .title : .headline))
                    .fontWeight(.bold)
                Text("After P\(period)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .ended:
            Text("FINAL")
                .font(.system(fontSize == .largeTitle ? .title2 : .headline))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        case .starting:
            Text("SOON")
                .font(.system(fontSize == .largeTitle ? .title2 : .headline))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Dynamic Island Expanded Views

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    var body: some View {
        HStack {
            VStack {
                Spacer()
                Image("Team/\(context.attributes.homeTeam.teamCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                Spacer()
            }
            Spacer()
            Text(String(context.state.homeScore))
                .font(.system(size: 48))
                .fontWidth(.compressed)
                .fontWeight(.bold)
                .foregroundStyle(context.state.homeScore >= context.state.awayScore ? .primary : .secondary)
        }
        .frame(width: 96)
    }
}

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    var body: some View {
        HStack {
            Text(String(context.state.awayScore))
                .font(.system(size: 48))
                .fontWidth(.compressed)
                .fontWeight(.bold)
                .transition(.moveDown)
                .foregroundStyle(context.state.awayScore >= context.state.homeScore ? .primary : .secondary)
            Spacer()
            VStack {
                Spacer()
                Image("Team/\(context.attributes.awayTeam.teamCode)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                Spacer()
            }
        }
        .frame(width: 96)
    }
}

private struct ExpandedCenterView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    var body: some View {
        VStack {
            HStack {
                switch context.state.period.state {
                case .ended:
                    Text("Ended")
                        .font(.title)
                        .fontWeight(.semibold)
                case .onbreak:
                    Text(cappedPeriodEnd(context.state.period.periodEnd), style: .timer)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .fontWeight(.semibold)
                case .ongoing, .overtime:
                    Text(cappedPeriodEnd(context.state.period.periodEnd), style: .timer)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .fontWeight(.semibold)
                case .starting:
                    Text("0:00")
                        .font(.title)
                        .fontWeight(.semibold)
                case .intermission:
                    Text("0:00")
                        .font(.title)
                        .fontWeight(.semibold)
                }
            }
            if context.state.period.state == .onbreak {
                Label("Pause", systemImage: "clock")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Label("P\(context.state.period.period)", systemImage: "clock")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Dynamic Island Compact Views

private struct CompactLeadingView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    var body: some View {
        HStack {
            Image("Team/\(context.attributes.homeTeam.teamCode)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
            Text(String(context.state.homeScore))
                .fontWeight(.semibold)
                .fontWidth(.compressed)
                .font(.system(size: 22))
                .foregroundStyle(context.state.homeScore >= context.state.awayScore ? .primary : .secondary)
        }
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    var body: some View {
        HStack {
            Text(String(context.state.awayScore))
                .fontWeight(.semibold)
                .fontWidth(.compressed)
                .font(.system(size: 22))
                .foregroundStyle(context.state.awayScore >= context.state.homeScore ? .primary : .secondary)
            Image("Team/\(context.attributes.awayTeam.teamCode)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Dynamic Island Minimal View

private struct MinimalView: View {
    let context: ActivityViewContext<SHLWidgetAttributes>

    var body: some View {
        if context.state.homeScore > context.state.awayScore {
            Image("Team/\(context.attributes.homeTeam.teamCode)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        } else if context.state.homeScore < context.state.awayScore {
            Image("Team/\(context.attributes.awayTeam.teamCode)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        } else {
            Text("\(context.state.homeScore)-\(context.state.awayScore)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }
}

// MARK: - Previews

extension SHLWidgetAttributes {
    fileprivate static var preview: SHLWidgetAttributes {
        SHLWidgetAttributes(
            id: "123",
            internalId: "preview-id",
            homeTeam: ActivityTeam(name: "Lulea Hockey", teamCode: "LHF"),
            awayTeam: ActivityTeam(name: "Frolunda HC", teamCode: "FHC")
        )
    }

    fileprivate static var previewState: SHLWidgetAttributes.ContentState {
        SHLWidgetAttributes.ContentState(
            homeScore: 3,
            awayScore: 2,
            period: SHLWidgetAttributes.ActivityPeriod(
                period: 2,
                periodEnd: Calendar.current.date(byAdding: .minute, value: 8, to: Date.now)?
                    .ISO8601Format(.Strategy(includingFractionalSeconds: true)) ?? "",
                state: .ongoing
            )
        )
    }

    fileprivate static var previewStateTied: SHLWidgetAttributes.ContentState {
        SHLWidgetAttributes.ContentState(
            homeScore: 2,
            awayScore: 2,
            period: SHLWidgetAttributes.ActivityPeriod(
                period: 3,
                periodEnd: Calendar.current.date(byAdding: .minute, value: 5, to: Date.now)?
                    .ISO8601Format(.Strategy(includingFractionalSeconds: true)) ?? "",
                state: .ongoing
            )
        )
    }

    fileprivate static var previewStateIntermission: SHLWidgetAttributes.ContentState {
        SHLWidgetAttributes.ContentState(
            homeScore: 2,
            awayScore: 1,
            period: SHLWidgetAttributes.ActivityPeriod(
                period: 2,
                periodEnd: "",
                state: .intermission
            )
        )
    }

    fileprivate static var previewStateEnded: SHLWidgetAttributes.ContentState {
        SHLWidgetAttributes.ContentState(
            homeScore: 4,
            awayScore: 2,
            period: SHLWidgetAttributes.ActivityPeriod(
                period: 3,
                periodEnd: "",
                state: .ended
            )
        )
    }
}

#Preview("Lock Screen - Live", as: .content, using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewState
}

#Preview("Lock Screen - Tied", as: .content, using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewStateTied
}

#Preview("Lock Screen - Intermission", as: .content, using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewStateIntermission
}

#Preview("Lock Screen - Final", as: .content, using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewStateEnded
}

#Preview("Minimal - Leading", as: .dynamicIsland(.minimal), using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewState
}

#Preview("Minimal - Tied", as: .dynamicIsland(.minimal), using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewStateTied
}

#Preview("Compact", as: .dynamicIsland(.compact), using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewState
}

#Preview("Expanded - Live", as: .dynamicIsland(.expanded), using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewState
}

#Preview("Expanded - Intermission", as: .dynamicIsland(.expanded), using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewStateIntermission
}

#Preview("Expanded - Final", as: .dynamicIsland(.expanded), using: SHLWidgetAttributes.preview) {
    SHLWidgetLiveActivity()
} contentStates: {
    SHLWidgetAttributes.previewStateEnded
}
