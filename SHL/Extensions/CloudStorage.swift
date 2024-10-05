//
//  CloudStorage.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 4/10/24.
//

import SwiftUI

@propertyWrapper
struct CloudStorage<T: Codable>: DynamicProperty {
    @State private var value: T
    private let key: String
    private let defaultValue: T
    
    init(key: String, default: T) {
        self.key = key
        self.defaultValue = `default`
        let initialValue = CloudStorage.getValue(key: key, default: `default`)
        self._value = State(initialValue: initialValue)
    }
    
    var wrappedValue: T {
        get { value }
        nonmutating set {
            value = newValue
            CloudStorage.setValue(newValue, key: key)
        }
    }
    
    var projectedValue: Binding<T> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    
    private static func getValue(key: String, default: T) -> T {
        if let data = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Data {
            let value = try? JSONDecoder().decode(T.self, from: data)
            return value ?? UserDefaults.standard.object(forKey: key) as? T ?? `default`
        } else if let localValue = UserDefaults.standard.object(forKey: key) as? T {
            return localValue
        }
        return `default`
    }
    
    private static func setValue(_ value: T, key: String) {
        Task {
            if let encoded = try? JSONEncoder().encode(value) {
                NSUbiquitousKeyValueStore.default.set(encoded, forKey: key)
                NSUbiquitousKeyValueStore.default.synchronize()
                
                // Also save to UserDefaults as a fallback
                UserDefaults.standard.set(value, forKey: key)
            }
        }
    }
}
