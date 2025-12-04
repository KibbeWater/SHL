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

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Goal -")
                        .fontWeight(.semibold)
                    Text("\(data.scorer.jersey) \(data.scorer.fullName)")
                }

                if let assists = data.assists, !assists.isEmpty {
                    HStack {
                        VStack {
                            Text("Assists:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Text(assists.map { "\($0.jersey) \($0.fullName)" }.joined(separator: ",\n"))
                            .font(.caption)
                    }
                }

                if let goalStatus = data.goalStatus {
                    HStack {
                        switch goalStatus {
                        case "PP1", "PP2":
                            Label("Power Play", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        case "SH":
                            Label("Short Handed", systemImage: "shield.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        default:
                            EmptyView()
                        }

                        if data.emptyNet {
                            Label("Empty Net", systemImage: "checkmark.shield")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }

                Text("P\(event.period) - \(event.gameTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            Spacer()

            HStack {
                let isHome = event.teamID == match.homeTeam.id
                Text(String(isHome ? data.homeScore : data.awayScore))
                    .font(.system(size: 48))
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                TeamLogoView(teamCode: isHome ? match.homeTeam.code : match.awayTeam.code, size: .medium)
            }
            .frame(width: 96)
        }
        .padding([.trailing, .vertical], 8)
        .padding(.leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Shot Event Row

struct ShotEventRow: View {
    let event: PBPEventDTO
    let data: ShotEventData
    let match: Match

    var body: some View {
        HStack {
            let isHome = event.teamID == match.homeTeam.id

            if isHome {
                TeamIndicator(color: .red)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Shot -")
                        .fontWeight(.semibold)
                    Text("\(data.shooter.jersey) \(data.shooter.fullName)")
                }

                if data.location.isBlocked {
                    Text("Blocked")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if data.location.isMiss {
                    Text("Missed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

// MARK: - Penalty Event Row

struct PenaltyEventRow: View {
    let event: PBPEventDTO
    let data: PenaltyEventData
    let match: Match

    var body: some View {
        HStack {
            let isHome = event.teamID == match.homeTeam.id

            if isHome {
                TeamIndicator(color: .red)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Penalty -")
                        .fontWeight(.semibold)
                    if let player = data.player {
                        Text("\(player.jersey) \(player.fullName)")
                    } else {
                        Text("Bench")
                    }
                }

                HStack {
                    Text(data.offence)
                        .font(.caption)
                    if let duration = data.duration {
                        Text("(\(duration) min)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
        VStack {
            if data.finished {
                Text("Period \(event.period) ended")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.vertical)
            } else if data.started {
                Text("Period \(event.period) started")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.vertical)
            }
        }
    }
}

// MARK: - Period Change Row

struct PeriodChangeRow: View {
    let event: PBPEventDTO
    let data: PeriodChangeData

    var body: some View {
        HStack {
            VStack {
                Text(data.fromLabel)
                    .foregroundStyle(.primary)
                Image(systemName: data.toPeriod > data.fromPeriod ? "arrow.down" : "arrow.up")
                    .padding(.vertical, 2)
                Text(data.toLabel)
                    .foregroundStyle(.primary)
            }
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
        }
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
