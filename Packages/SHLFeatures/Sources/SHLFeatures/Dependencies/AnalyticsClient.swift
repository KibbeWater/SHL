import ComposableArchitecture

public struct AnalyticsClient: Sendable {
    public var capture: @Sendable (_ event: String, _ properties: [String: Any]) -> Void

    public init(capture: @escaping @Sendable (String, [String: Any]) -> Void) {
        self.capture = capture
    }
}

extension AnalyticsClient: DependencyKey {
    public static let liveValue = Self { _, _ in
        // PostHog is in the app layer — the app will override this
    }
}

extension DependencyValues {
    public var analytics: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
