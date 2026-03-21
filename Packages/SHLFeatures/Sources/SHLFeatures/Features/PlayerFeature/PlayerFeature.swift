import ComposableArchitecture
import Foundation
import SHLNetwork

@Reducer
public struct PlayerFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public let playerId: String
        public var player: Player?
        public var stats: [PlayerGameLog]
        public var isLoading: Bool

        public init(player: Player) {
            self.playerId = player.id
            self.player = player
            self.stats = []
            self.isLoading = false
        }

        public init(playerId: String) {
            self.playerId = playerId
            self.player = nil
            self.stats = []
            self.isLoading = false
        }

        // MARK: - Computed Properties

        public var isGoalie: Bool {
            player?.position == .goalkeeper || stats.first?.isGoalie == true
        }

        public var currentSeasonStats: [PlayerGameLog] {
            stats.filter { $0.season.isCurrent }
        }

        public var statsGroupedBySeason: [(season: SeasonDTO, stats: [PlayerGameLog])] {
            let grouped = Dictionary(grouping: stats) { $0.season }
            return grouped.map { (season: $0.key, stats: $0.value) }
                .sorted {
                    $0.season.isCurrent
                        || ($0.season.startDate ?? Date.distantPast)
                            > ($1.season.startDate ?? Date.distantPast)
                }
        }

        public var currentSeasonName: String {
            currentSeasonStats.first?.season.name ?? "N/A"
        }

        // MARK: - Career Totals (Skater)

        public var careerTotalsSkater: SkaterTotals {
            SkaterTotals.compute(from: stats)
        }

        public var currentSeasonTotalsSkater: SkaterTotals {
            SkaterTotals.compute(from: currentSeasonStats)
        }

        // MARK: - Career Totals (Goalie)

        public var careerTotalsGoalie: GoalieTotals {
            GoalieTotals.compute(from: stats)
        }

        public var currentSeasonTotalsGoalie: GoalieTotals {
            GoalieTotals.compute(from: currentSeasonStats)
        }

        // MARK: - Equatable

        public static func == (lhs: State, rhs: State) -> Bool {
            lhs.playerId == rhs.playerId
                && lhs.player?.id == rhs.player?.id
                && lhs.player?.fullName == rhs.player?.fullName
                && lhs.player?.position == rhs.player?.position
                && lhs.player?.jerseyNumber == rhs.player?.jerseyNumber
                && lhs.player?.teamID == rhs.player?.teamID
                && lhs.player?.portraitURL == rhs.player?.portraitURL
                && lhs.stats == rhs.stats
                && lhs.isLoading == rhs.isLoading
        }
    }

    // MARK: - Actions

    public enum Action {
        case onAppear
        case refresh
        case playerLoaded(Player)
        case statsLoaded([PlayerGameLog])
        case loadFailed
    }

    // MARK: - Dependencies

    @Dependency(\.apiClient) var apiClient

    // MARK: - Init

    public init() {}

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                let playerId = state.playerId
                return .run { send in
                    do {
                        let player = try await apiClient.getPlayerDetail(playerId)
                        await send(.playerLoaded(player))
                        let stats = try await apiClient.getPlayerStats(player.id)
                        await send(.statsLoaded(stats))
                    } catch {
                        await send(.loadFailed)
                    }
                }

            case .refresh:
                state.isLoading = true
                let playerId = state.playerId
                return .run { send in
                    do {
                        let player = try await apiClient.getPlayerDetail(playerId)
                        await send(.playerLoaded(player))
                        let stats = try await apiClient.getPlayerStats(player.id)
                        await send(.statsLoaded(stats))
                    } catch {
                        await send(.loadFailed)
                    }
                }

            case let .playerLoaded(player):
                state.player = player
                return .none

            case let .statsLoaded(stats):
                state.stats = stats
                state.isLoading = false
                return .none

            case .loadFailed:
                state.isLoading = false
                return .none
            }
        }
    }
}

// MARK: - Totals Types

public struct SkaterTotals: Equatable {
    public let gamesPlayed: Int
    public let goals: Int
    public let assists: Int
    public let points: Int
    public let penaltyMinutes: Int
    public let plusMinus: Int
    public let shotsOnGoal: Int
    public let shootingPercentage: Double?
    public let powerPlayGoals: Int
    public let shortHandedGoals: Int

    public static func compute(from stats: [PlayerGameLog]) -> SkaterTotals {
        let totalGP = stats.reduce(0) { $0 + $1.gamesPlayed }
        let totalGoals = stats.reduce(0) { $0 + $1.goals }
        let totalAssists = stats.reduce(0) { $0 + $1.assists }
        let totalPoints = stats.reduce(0) { $0 + $1.points }
        let totalPIM = stats.reduce(0) { $0 + $1.penaltyMinutes }
        let totalPlusMinus = stats.reduce(0) { $0 + ($1.plusMinus ?? 0) }
        let totalSOG = stats.reduce(0) { $0 + ($1.advancedStats?.shotsOnGoal ?? 0) }
        let totalPPG = stats.reduce(0) { $0 + ($1.advancedStats?.powerPlayGoals ?? 0) }
        let totalSHG = stats.reduce(0) { $0 + ($1.advancedStats?.shortHandedGoals ?? 0) }
        let shootingPct = totalSOG > 0 ? Double(totalGoals) / Double(totalSOG) : nil

        return SkaterTotals(
            gamesPlayed: totalGP,
            goals: totalGoals,
            assists: totalAssists,
            points: totalPoints,
            penaltyMinutes: totalPIM,
            plusMinus: totalPlusMinus,
            shotsOnGoal: totalSOG,
            shootingPercentage: shootingPct,
            powerPlayGoals: totalPPG,
            shortHandedGoals: totalSHG
        )
    }
}

public struct GoalieTotals: Equatable {
    public let gamesPlayed: Int
    public let gamesPlayedIn: Int
    public let wins: Int
    public let losses: Int
    public let ties: Int
    public let shutouts: Int
    public let saves: Int
    public let goalsAgainst: Int
    public let savePercentage: Double?
    public let goalsAgainstAverage: Double?

    public static func compute(from stats: [PlayerGameLog]) -> GoalieTotals {
        let totalGP = stats.reduce(0) { $0 + $1.gamesPlayed }
        let totalGPI = stats.reduce(0) { $0 + ($1.goalieStats?.gamesPlayedIn ?? 0) }
        let totalWins = stats.reduce(0) { $0 + ($1.goalieStats?.wins ?? 0) }
        let totalLosses = stats.reduce(0) { $0 + ($1.goalieStats?.losses ?? 0) }
        let totalTies = stats.reduce(0) { $0 + ($1.goalieStats?.ties ?? 0) }
        let totalShutouts = stats.reduce(0) { $0 + ($1.goalieStats?.shutouts ?? 0) }
        let totalSaves = stats.reduce(0) { $0 + ($1.goalieStats?.saves ?? 0) }
        let totalGA = stats.reduce(0) { $0 + ($1.goalieStats?.goalsAgainst ?? 0) }
        let savePct = (totalSaves + totalGA) > 0 ? Double(totalSaves) / Double(totalSaves + totalGA) : nil
        let gaa = totalGPI > 0 ? Double(totalGA) / Double(totalGPI) : nil

        return GoalieTotals(
            gamesPlayed: totalGP,
            gamesPlayedIn: totalGPI,
            wins: totalWins,
            losses: totalLosses,
            ties: totalTies,
            shutouts: totalShutouts,
            saves: totalSaves,
            goalsAgainst: totalGA,
            savePercentage: savePct,
            goalsAgainstAverage: gaa
        )
    }
}
