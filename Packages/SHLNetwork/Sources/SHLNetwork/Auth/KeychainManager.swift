//
//  KeychainManager.swift
//  SHLNetwork
//
//  Created by Claude Code
//

import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif

/// Manager for securely storing sensitive data in the iOS Keychain with iCloud sync support
public final class KeychainManager: KeychainProviding, @unchecked Sendable {
    public static let shared = KeychainManager()

    /// Closure that returns whether keychain iCloud sync is enabled.
    /// Set this from the app layer (e.g., `KeychainManager.shared.keychainSyncEnabledProvider = { keychainSyncEnabledProvider() }`)
    public var keychainSyncEnabledProvider: () -> Bool = { false }

    private init() {}

    // MARK: - Keychain Keys

    private enum Keys {
        static let jwtToken = "com.shl.jwtToken"
        static let userId = "com.shl.userId"
        static let deviceId = "com.shl.deviceId"
        static let fallbackDeviceId = "com.shl.fallbackDeviceId"
        static let tokenExpiresAt = "com.shl.tokenExpiresAt"
    }

    // MARK: - Public Methods

    /// Save JWT token to keychain with optional iCloud sync (based on user preference)
    public func saveToken(_ token: String, expiresAt: Date) {
        let syncEnabled = keychainSyncEnabledProvider()
        save(token, forKey: Keys.jwtToken, syncWithiCloud: syncEnabled)
        save(ISO8601DateFormatter().string(from: expiresAt), forKey: Keys.tokenExpiresAt, syncWithiCloud: syncEnabled)
    }

    /// Retrieve JWT token from keychain
    public func getToken() -> String? {
        return retrieve(forKey: Keys.jwtToken)
    }

    /// Get token expiration date
    public func getTokenExpiresAt() -> Date? {
        guard let dateString = retrieve(forKey: Keys.tokenExpiresAt),
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        return date
    }

    /// Check if token is expired or will expire soon (within 7 days)
    public func isTokenExpiringSoon() -> Bool {
        guard let expiresAt = getTokenExpiresAt() else {
            return true
        }
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return expiresAt < sevenDaysFromNow
    }

    /// Delete JWT token from keychain
    public func deleteToken() {
        delete(forKey: Keys.jwtToken)
        delete(forKey: Keys.tokenExpiresAt)
    }

    /// Save user ID to keychain with optional iCloud sync (based on user preference)
    public func saveUserId(_ userId: String) {
        let syncEnabled = keychainSyncEnabledProvider()
        save(userId, forKey: Keys.userId, syncWithiCloud: syncEnabled)
    }

    /// Retrieve user ID from keychain
    public func getUserId() -> String? {
        return retrieve(forKey: Keys.userId)
    }

    /// Delete user ID from keychain
    public func deleteUserId() {
        delete(forKey: Keys.userId)
    }

    /// Get or create a persistent device ID (IDFV)
    public func getDeviceId() -> String {
        if let existingId = retrieve(forKey: Keys.deviceId) {
            return existingId
        }

        #if canImport(UIKit)
        // Use IDFV as primary device identifier
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        let deviceId = UUID().uuidString
        #endif
        save(deviceId, forKey: Keys.deviceId, syncWithiCloud: false)
        return deviceId
    }

    /// Get or create a fallback device ID that persists across app reinstalls
    public func getFallbackDeviceId() -> String {
        if let existingId = retrieve(forKey: Keys.fallbackDeviceId) {
            return existingId
        }

        // Create persistent UUID that survives app reinstalls (stored in keychain)
        let fallbackId = UUID().uuidString
        let syncEnabled = keychainSyncEnabledProvider()
        save(fallbackId, forKey: Keys.fallbackDeviceId, syncWithiCloud: syncEnabled)
        return fallbackId
    }

    /// Clear all authentication data
    public func clearAllAuthData() {
        deleteToken()
        deleteUserId()
        // Keep device IDs for potential re-authentication
    }

    // MARK: - Private Keychain Operations

    private func save(_ value: String, forKey key: String, syncWithiCloud: Bool) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item if any
        delete(forKey: key)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Enable iCloud Keychain sync if requested
        if syncWithiCloud {
            query[kSecAttrSynchronizable as String] = true
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Keychain save failed for key '\(key)': \(status)")
        }
    }

    private func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny // Check both iCloud and local
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]

        SecItemDelete(query as CFDictionary)
    }
}
