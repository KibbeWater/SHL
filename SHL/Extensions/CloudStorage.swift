//
//  CloudStorage.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 4/10/24.
//

import SwiftUI

import SwiftUI
import Combine

@propertyWrapper
class CloudStorage<Value: Codable>: DynamicProperty {
    private let key: String
    private let defaultValue: Value
    private var cancellable: AnyCancellable?

    // UserDefaults & iCloud stores
    private let userDefaults: UserDefaults
    private let ubiquitousStore = NSUbiquitousKeyValueStore.default
    
    // Internal value holder
    @Published private var currentValue: Value {
        didSet {
            // Sync with UserDefaults and iCloud
            CloudStorage.setValue(currentValue, forKey: key)
        }
    }
    
    // Projected value will expose a Binding<Value>
    var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
            }
        )
    }

    // Wrapped value is where the getter and setter logic is applied
    var wrappedValue: Value {
        get {
            return currentValue
        }
        set {
            currentValue = newValue
        }
    }

    // Initializer
    init(key: String, default: Value) {
        self.key = key
        self.defaultValue = `default`
        self.userDefaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier) ?? UserDefaults.standard
        self.currentValue = CloudStorage.getValue(forKey: key, defaultValue: `default`)
        
        // Observe iCloud changes
        cancellable = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                self?.syncFromICloud(notification: notification)
            }
    }

    // Load initial value from iCloud/UserDefaults
    private func syncFromICloud(notification: Notification) {
        if let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
           changedKeys.contains(key),
           let data = ubiquitousStore.data(forKey: key),
           let decodedValue = CloudStorage.decode(data) as Value? {
            currentValue = decodedValue
        }
    }

    // MARK: - Static Methods
    
    // Static method to get a value
    static func getValue(forKey key: String, defaultValue: Value) -> Value {
        let userDefaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier) ?? UserDefaults.standard
        let ubiquitousStore = NSUbiquitousKeyValueStore.default
        
        // Try to retrieve value from UserDefaults first
        if let data = userDefaults.data(forKey: key),
           let value = decode(data) as Value? {
            return value
        }
        
        // If not found, try from iCloud
        if let data = ubiquitousStore.data(forKey: key),
           let value = decode(data) as Value? {
            return value
        }
        
        // Return the default value if no data is found
        return defaultValue
    }

    // Static method to set a value
    static func setValue(_ value: Value, forKey key: String) {
        let userDefaults = UserDefaults(suiteName: SharedPreferenceKeys.groupIdentifier) ?? UserDefaults.standard
        let ubiquitousStore = NSUbiquitousKeyValueStore.default
        
        // Encode the value to Data
        if let data = try? JSONEncoder().encode(value) {
            // Save to UserDefaults
            userDefaults.set(data, forKey: key)
            
            // Save to iCloud
            ubiquitousStore.set(data, forKey: key)
            ubiquitousStore.synchronize() // Explicitly sync iCloud
        }
    }

    // Helper method to decode JSON data into the desired Value type
    private static func decode(_ data: Data) -> Value? {
        return try? JSONDecoder().decode(Value.self, from: data)
    }
}

