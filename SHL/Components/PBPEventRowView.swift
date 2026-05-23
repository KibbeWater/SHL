//
//  PBPEventRowView.swift
//  SHL
//
//  View component for rendering individual PBP events
//

import SwiftUI

struct PBPEventRowView: View {
    let event: PBPEventDTO
    let match: Match

    var body: some View {
        Group {
            switch event.typedEventType {
            case .goal:
                if let goalData = event.data?.asGoal {
                    GoalEventRow(event: event, data: goalData, match: match)
                }
            case .shot:
                if let shotData = event.data?.asShot {
                    ShotEventRow(event: event, data: shotData, match: match)
                }
            case .penalty:
                if let penaltyData = event.data?.asPenalty {
                    PenaltyEventRow(event: event, data: penaltyData, match: match)
                }
            case .goalkeeper:
                if let goalkeeperData = event.data?.asGoalkeeper {
                    GoalkeeperEventRow(event: event, data: goalkeeperData, match: match)
                }
            case .timeout:
                if let timeoutData = event.data?.asTimeout {
                    TimeoutEventRow(event: event, data: timeoutData, match: match)
                }
            case .shootout:
                if let shootoutData = event.data?.asShootout {
                    ShootoutEventRow(event: event, data: shootoutData, match: match)
                }
            case .period:
                if let periodData = event.data?.asPeriod {
                    PeriodEventRow(event: event, data: periodData)
                }
            case .periodChange:
                if let periodChangeData = event.data?.asPeriodChange {
                    PeriodChangeRow(event: event, data: periodChangeData)
                }
            case .unknown:
                EmptyView()
            }
        }
    }
}

// MARK: - Goal Event Row

struct GoalEventRow: View {
    let event: PBPEventDTO
    let data: GoalEventData
    let match: Match

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Goal puck/icon indicator
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "hockey.puck.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: appeared)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("GOAL")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: .capsule)
                    Text("#\(data.scorer.jersey) \(data.scorer.fullName)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                if let assists = data.assists, !assists.isEmpty {
                    Text("Assists: \(assists.map { "#\($0.jersey) \($0.fullName)" }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let goalStatus = data.goalStatus {
                        switch goalStatus {
                        case "PP1", "PP2":
                            Label("Power Play", systemImage: "bolt.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                                .symbolRenderingMode(.hierarchical)
                        case "SH":
                            Label("Short Handed", systemImage: "shield.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.blue)
                                .symbolRenderingMode(.hierarchical)
                        default:
                            EmptyView()
                        }
                    }

                    if data.emptyNet {
                        Label("Empty Net", systemImage: "checkmark.shield.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Text("P\(event.period) • \(event.gameTime)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer()

            HStack(spacing: 6) {
                let isHome = event.teamID == match.homeTeam.id
                Text(String(isHome ? data.homeScore : data.awayScore))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .fontWidth(.compressed)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                TeamLogoView(teamCode: isHome ? match.homeTeam.code : match.awayTeam.code, size: .custom(40))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.green.opacity(0.25), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: appeared) { _, new in new }
    }
}

// MARK: - Shot Event Row

struct ShotEventRow: View {
    let event: PBPEventDTO
    let data: ShotEventData
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            let isHome = event.teamID == match.homeTeam.id

            TeamLogoView(teamCode: isHome ? match.homeTeam.code : match.awayTeam.code, size: .custom(28))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Shot")
                        .font(.subheadline.weight(.semibold))
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("#\(data.shooter.jersey) \(data.shooter.fullName)")
                        .font(.subheadline)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if data.location.isBlocked {
                        Label("Blocked", systemImage: "shield.lefthalf.filled")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    } else if data.location.isMiss {
                        Label("Missed", systemImage: "xmark.circle")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("P\(event.period) • \(event.gameTime)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Penalty Event Row

struct PenaltyEventRow: View {
    let event: PBPEventDTO
    let data: PenaltyEventData
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            let isHome = event.teamID == match.homeTeam.id

            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("PENALTY")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.15), in: .capsule)

                    if let player = data.player {
                        Text("#\(player.jersey) \(player.fullName)")
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    } else {
                        Text("Bench")
                            .font(.subheadline.weight(.medium))
                    }
                }

                HStack(spacing: 6) {
                    Text(data.offence)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let duration = data.duration {
                        Text("(\(duration) min)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }

                Text("P\(event.period) • \(event.gameTime)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            Spacer()

            TeamLogoView(teamCode: isHome ? match.homeTeam.code : match.awayTeam.code, size: .custom(32))
        }
        .padding(12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Goalkeeper Event Row

struct GoalkeeperEventRow: View {
    let event: PBPEventDTO
    let data: GoalkeeperEventData
    let match: Match

    var body: some View {
        HStack {
            let isHome = event.teamID == match.homeTeam.id

            if isHome {
                TeamIndicator(color: .red)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Goalkeeper \(data.entering ? "In" : "Out") -")
                        .fontWeight(.semibold)
                    Text("\(data.goalie.jersey) \(data.goalie.fullName)")
                }

                Text("P\(event.period) - \(event.gameTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, !isHome ? 16 : 0)

            Spacer()

            if !isHome {
                TeamIndicator(color: .blue)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Timeout Event Row

struct TimeoutEventRow: View {
    let event: PBPEventDTO
    let data: TimeoutEventData
    let match: Match

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Tactical Timeout")
                    .fontWeight(.semibold)

                Text("P\(event.period) - \(event.gameTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let isHome = event.teamID == match.homeTeam.id
            TeamLogoView(teamCode: isHome ? match.homeTeam.code : match.awayTeam.code, size: .medium)
        }
        .padding([.trailing, .vertical], 8)
        .padding(.leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Shootout Event Row

struct ShootoutEventRow: View {
    let event: PBPEventDTO
    let data: ShootoutEventData
    let match: Match

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Shootout")
                        .fontWeight(.semibold)
                    Text("Round \(data.round)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("\(data.shooter.jersey) \(data.shooter.fullName)")
                    if data.isGoal {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if data.isGameWinner {
                    Text("Game Winner!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
            }

            Spacer()

            VStack {
                Text("\(data.shootoutScore.home) - \(data.shootoutScore.away)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding([.trailing, .vertical], 8)
        .padding(.leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Period Event Row

struct PeriodEventRow: View {
    let event: PBPEventDTO
    let data: PeriodEventData

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(.tertiary)
                .frame(height: 0.5)
            if data.finished {
                Label("Period \(event.period) ended", systemImage: "stop.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            } else if data.started {
                Label("Period \(event.period) started", systemImage: "play.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            Rectangle()
                .fill(.tertiary)
                .frame(height: 0.5)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Period Change Row

struct PeriodChangeRow: View {
    let event: PBPEventDTO
    let data: PeriodChangeData

    var body: some View {
        VStack(spacing: 4) {
            Text(data.fromLabel)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
            Image(systemName: data.toPeriod > data.fromPeriod ? "arrow.down" : "arrow.up")
                .font(.subheadline)
                .foregroundStyle(.tint)
            Text(data.toLabel)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary, in: .rect(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Helper Views

struct TeamIndicator: View {
    let color: Color

    var body: some View {
        VStack {}
            .frame(maxHeight: .infinity)
            .frame(width: 6)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
    }
}
