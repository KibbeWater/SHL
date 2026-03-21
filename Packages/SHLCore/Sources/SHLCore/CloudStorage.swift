//
//  CloudStorage.swift
//  SHLCore
//

import SwiftUI
import Combine

@propertyWrapper
public class CloudStorage<Value: Codable>: DynamicProperty {
    private let key: String
    private let defaultValue: Value
    private var cancellable: AnyCancellable?

    private let userDefaults: UserDefaults
    private let ubiquitousStore = NSUbiquitousKeyValueStore.default

    @Published private var currentValue: Value {
        didSet {
            CloudStorage.setValue(currentValue, forKey: key)
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
            }
        )
    }

    public var wrappedValue: Value {
        get {
            return currentValue
        }
        set {
            currentValue = newValue
        }
    }

    public init(key: String, default: Value) {
        self.key = key
        self.defaultValue = `default`
        self.userDefaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier) ?? UserDefaults.standard
        self.currentValue = CloudStorage.getValue(forKey: key, defaultValue: `default`)

        cancellable = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                self?.syncFromICloud(notification: notification)
            }
    }

    private func syncFromICloud(notification: Notification) {
        if let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
           changedKeys.contains(key),
           let data = ubiquitousStore.data(forKey: key),
           let decodedValue = CloudStorage.decode(data) as Value? {
            currentValue = decodedValue
        }
    }

    public static func getValue(forKey key: String, defaultValue: Value) -> Value {
        let userDefaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier) ?? UserDefaults.standard
        let ubiquitousStore = NSUbiquitousKeyValueStore.default

        if let data = userDefaults.data(forKey: key),
           let value = decode(data) as Value? {
            return value
        }

        if let data = ubiquitousStore.data(forKey: key),
           let value = decode(data) as Value? {
            return value
        }

        return defaultValue
    }

    public static func setValue(_ value: Value, forKey key: String) {
        let userDefaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier) ?? UserDefaults.standard
        let ubiquitousStore = NSUbiquitousKeyValueStore.default

        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
            ubiquitousStore.set(data, forKey: key)
            ubiquitousStore.synchronize()
        }
    }

    private static func decode(_ data: Data) -> Value? {
        return try? JSONDecoder().decode(Value.self, from: data)
    }
}
