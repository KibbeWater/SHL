import ComposableArchitecture
import SHLNetwork
import SHLCore

@Reducer
public struct SettingsFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        // Account
        public var userManagementEnabled: Bool
        public var keychainSyncEnabled: Bool
        public var hasCompletedOnboarding: Bool

        // Notifications
        public var notificationSettings: NotificationSettings

        // Auth
        public var isAuthenticated: Bool
        public var userId: String?

        // Push
        public var pushTokenStatus: PushTokenStatus

        // Teams
        public var teams: [Team]
        public var teamsLoaded: Bool
        public var interestedTeams: [InterestedTeam]
        public var favoriteTeam: InterestedTeam?

        // Devices
        public var devices: [Device]
        public var isLoadingDevices: Bool

        // Alerts / Sheets
        public var showDeleteAccountAlert: Bool
        public var showTeamSelectionSheet: Bool
        public var showFavoriteTeamPicker: Bool
        public var showResetOnboardingAlert: Bool

        public init() {
            let settings = Settings.shared
            self.userManagementEnabled = settings.userManagementEnabled
            self.keychainSyncEnabled = settings.keychainSyncEnabled
            self.hasCompletedOnboarding = settings.hasCompletedOnboarding
            self.notificationSettings = settings.notificationSettings
            self.isAuthenticated = false
            self.userId = nil
            self.pushTokenStatus = .unknown
            self.teams = []
            self.teamsLoaded = false
            self.interestedTeams = settings.getInterestedTeams()
            self.favoriteTeam = settings.getFavoriteTeam()
            self.devices = []
            self.isLoadingDevices = false
            self.showDeleteAccountAlert = false
            self.showTeamSelectionSheet = false
            self.showFavoriteTeamPicker = false
            self.showResetOnboardingAlert = false
        }
    }

    // MARK: - Push Token Status

    public enum PushTokenStatus: Equatable, Sendable {
        case unknown
        case authorized
        case denied
        case notDetermined
        case provisional
        case registeredWithBackend
    }

    // MARK: - Action

    public enum Action {
        // Lifecycle
        case onAppear

        // Account
        case toggleUserManagement(Bool)
        case toggleKeychainSync(Bool)

        // Notifications
        case updateNotificationSettings(NotificationSettings)
        case toggleMatchReminders(Bool)
        case toggleMatchResults(Bool)
        case toggleLiveGoals(Bool)
        case togglePeriodUpdates(Bool)
        case toggleAutoStartLiveActivity(Bool)

        // Auth
        case deleteAccountTapped
        case deleteAccountConfirmed
        case deleteAccountCancelled
        case logoutTapped
        case authStateUpdated(isAuthenticated: Bool, userId: String?)

        // Teams
        case teamsLoaded([Team])
        case teamsLoadFailed
        case teamSelectionTapped
        case teamSelectionDismissed
        case teamsSelected([String])
        case favoriteTeamPickerTapped
        case favoriteTeamPickerDismissed
        case favoriteTeamSelected(String?)

        // Devices
        case viewDevicesTapped
        case devicesLoaded([Device])
        case devicesLoadFailed

        // Push
        case pushTokenStatusUpdated(PushTokenStatus)
        case enablePushNotificationsTapped
        case registerTokenTapped

        // Onboarding
        case resetOnboardingTapped
        case resetOnboardingConfirmed
        case resetOnboardingCancelled

        // Delegate (for parent reducers to observe)
        case delegate(Delegate)

        public enum Delegate: Equatable, Sendable {
            case settingsDidChange
        }
    }

    // MARK: - Dependencies

    @Dependency(\.apiClient) var apiClient

    // MARK: - Init

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: Lifecycle

            case .onAppear:
                return .run { send in
                    do {
                        let teams = try await apiClient.getTeams()
                        let sorted = teams.sorted { $0.name < $1.name }
                        await send(.teamsLoaded(sorted))
                    } catch {
                        await send(.teamsLoadFailed)
                    }
                }

            // MARK: Account

            case let .toggleUserManagement(enabled):
                state.userManagementEnabled = enabled
                Settings.shared.userManagementEnabled = enabled
                return .send(.delegate(.settingsDidChange))

            case let .toggleKeychainSync(enabled):
                state.keychainSyncEnabled = enabled
                Settings.shared.keychainSyncEnabled = enabled
                return .send(.delegate(.settingsDidChange))

            // MARK: Notifications

            case let .updateNotificationSettings(newSettings):
                state.notificationSettings = newSettings
                Settings.shared.notificationSettings = newSettings
                return .send(.delegate(.settingsDidChange))

            case let .toggleMatchReminders(enabled):
                state.notificationSettings.matchReminders = enabled
                Settings.shared.notificationSettings = state.notificationSettings
                return .send(.delegate(.settingsDidChange))

            case let .toggleMatchResults(enabled):
                state.notificationSettings.matchResults = enabled
                Settings.shared.notificationSettings = state.notificationSettings
                return .send(.delegate(.settingsDidChange))

            case let .toggleLiveGoals(enabled):
                state.notificationSettings.liveGoals = enabled
                Settings.shared.notificationSettings = state.notificationSettings
                return .send(.delegate(.settingsDidChange))

            case let .togglePeriodUpdates(enabled):
                state.notificationSettings.periodUpdates = enabled
                Settings.shared.notificationSettings = state.notificationSettings
                return .send(.delegate(.settingsDidChange))

            case let .toggleAutoStartLiveActivity(enabled):
                state.notificationSettings.autoStartLiveActivity = enabled
                Settings.shared.notificationSettings = state.notificationSettings
                return .send(.delegate(.settingsDidChange))

            // MARK: Auth

            case .deleteAccountTapped:
                state.showDeleteAccountAlert = true
                return .none

            case .deleteAccountConfirmed:
                state.showDeleteAccountAlert = false
                return .run { send in
                    try? await AuthenticationManager.shared.deleteAccount()
                    await MainActor.run {
                        let isAuth = AuthenticationManager.shared.isAuthenticated
                        let userId = AuthenticationManager.shared.currentUserId
                        Task { await send(.authStateUpdated(isAuthenticated: isAuth, userId: userId)) }
                    }
                }

            case .deleteAccountCancelled:
                state.showDeleteAccountAlert = false
                return .none

            case .logoutTapped:
                return .run { send in
                    try? await AuthenticationManager.shared.logout()
                    await MainActor.run {
                        let isAuth = AuthenticationManager.shared.isAuthenticated
                        let userId = AuthenticationManager.shared.currentUserId
                        Task { await send(.authStateUpdated(isAuthenticated: isAuth, userId: userId)) }
                    }
                }

            case let .authStateUpdated(isAuthenticated, userId):
                state.isAuthenticated = isAuthenticated
                state.userId = userId
                return .none

            // MARK: Teams

            case let .teamsLoaded(teams):
                state.teams = teams
                state.teamsLoaded = true

                // Refresh cached interested teams from loaded team data
                let interestedIds = Settings.shared.getInterestedTeamIds()
                if !interestedIds.isEmpty {
                    let cachedTeams = interestedIds.compactMap { id in
                        teams.first(where: { $0.id == id }).map { team in
                            InterestedTeam(id: team.id, name: team.name, code: team.code, city: nil)
                        }
                    }
                    Settings.shared.cacheInterestedTeams(cachedTeams)
                    state.interestedTeams = cachedTeams
                    state.favoriteTeam = Settings.shared.getFavoriteTeam()
                }
                return .none

            case .teamsLoadFailed:
                return .none

            case .teamSelectionTapped:
                state.showTeamSelectionSheet = true
                return .none

            case .teamSelectionDismissed:
                state.showTeamSelectionSheet = false
                return .none

            case let .teamsSelected(selectedIds):
                let selectedTeams = selectedIds.compactMap { id in
                    state.teams.first(where: { $0.id == id }).map { team in
                        InterestedTeam(id: team.id, name: team.name, code: team.code, city: nil)
                    }
                }
                Settings.shared.setInterestedTeams(selectedTeams)
                state.interestedTeams = selectedTeams
                state.favoriteTeam = Settings.shared.getFavoriteTeam()
                state.showTeamSelectionSheet = false
                return .send(.delegate(.settingsDidChange))

            case .favoriteTeamPickerTapped:
                state.showFavoriteTeamPicker = true
                return .none

            case .favoriteTeamPickerDismissed:
                state.showFavoriteTeamPicker = false
                return .none

            case let .favoriteTeamSelected(teamId):
                Settings.shared.setFavoriteTeamId(teamId)
                state.favoriteTeam = Settings.shared.getFavoriteTeam()
                state.showFavoriteTeamPicker = false
                return .send(.delegate(.settingsDidChange))

            // MARK: Devices

            case .viewDevicesTapped:
                state.isLoadingDevices = true
                return .run { send in
                    do {
                        nonisolated(unsafe) let client = SHLAPIClient.shared
                        let response = try await client.getDevices()
                        await send(.devicesLoaded(response.devices))
                    } catch {
                        await send(.devicesLoadFailed)
                    }
                }

            case let .devicesLoaded(devices):
                state.devices = devices
                state.isLoadingDevices = false
                return .none

            case .devicesLoadFailed:
                state.isLoadingDevices = false
                return .none

            // MARK: Push

            case let .pushTokenStatusUpdated(status):
                state.pushTokenStatus = status
                return .none

            case .enablePushNotificationsTapped:
                #if os(iOS)
                return .run { send in
                    _ = await PushNotificationManager.shared.requestPermissionsAndRegister()
                    await send(.pushTokenStatusUpdated(.authorized))
                }
                #else
                return .none
                #endif

            case .registerTokenTapped:
                #if os(iOS)
                return .run { _ in
                    try? await PushNotificationManager.shared.registerTokenWithBackend()
                }
                #else
                return .none
                #endif

            // MARK: Onboarding

            case .resetOnboardingTapped:
                state.showResetOnboardingAlert = true
                return .none

            case .resetOnboardingConfirmed:
                state.showResetOnboardingAlert = false
                state.hasCompletedOnboarding = false
                Settings.shared.hasCompletedOnboarding = false
                return .none

            case .resetOnboardingCancelled:
                state.showResetOnboardingAlert = false
                return .none

            // MARK: Delegate

            case .delegate:
                return .none
            }
        }
    }
}
