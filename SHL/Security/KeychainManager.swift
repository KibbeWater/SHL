//
//  KeychainManager.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation
import Security
import UIKit

/// Manager for securely storing sensitive data in the iOS Keychain with iCloud sync support
final class KeychainManager {
    static let shared = KeychainManager()

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

    /// Save JWT token to keychain with iCloud sync
    func saveToken(_ token: String, expiresAt: Date) {
        save(token, forKey: Keys.jwtToken, syncWithiCloud: true)
        save(ISO8601DateFormatter().string(from: expiresAt), forKey: Keys.tokenExpiresAt, syncWithiCloud: true)
    }

    /// Retrieve JWT token from keychain
    func getToken() -> String? {
        return retrieve(forKey: Keys.jwtToken)
    }

    /// Get token expiration date
    func getTokenExpiresAt() -> Date? {
        guard let dateString = retrieve(forKey: Keys.tokenExpiresAt),
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        return date
    }

    /// Check if token is expired or will expire soon (within 7 days)
    func isTokenExpiringSoon() -> Bool {
        guard let expiresAt = getTokenExpiresAt() else {
            return true
        }
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return expiresAt < sevenDaysFromNow
    }

    /// Delete JWT token from keychain
    func deleteToken() {
        delete(forKey: Keys.jwtToken)
        delete(forKey: Keys.tokenExpiresAt)
    }

    /// Save user ID to keychain with iCloud sync
    func saveUserId(_ userId: String) {
        save(userId, forKey: Keys.userId, syncWithiCloud: true)
    }

    /// Retrieve user ID from keychain
    func getUserId() -> String? {
        return retrieve(forKey: Keys.userId)
    }

    /// Delete user ID from keychain
    func deleteUserId() {
        delete(forKey: Keys.userId)
    }

    /// Get or create a persistent device ID (IDFV)
    func getDeviceId() -> String {
        if let existingId = retrieve(forKey: Keys.deviceId) {
            return existingId
        }

        // Use IDFV as primary device identifier
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        save(deviceId, forKey: Keys.deviceId, syncWithiCloud: false)
        return deviceId
    }

    /// Get or create a fallback device ID that persists across app reinstalls
    func getFallbackDeviceId() -> String {
        if let existingId = retrieve(forKey: Keys.fallbackDeviceId) {
            return existingId
        }

        // Create persistent UUID that survives app reinstalls (stored in keychain)
        let fallbackId = UUID().uuidString
        save(fallbackId, forKey: Keys.fallbackDeviceId, syncWithiCloud: true)
        return fallbackId
    }

    /// Clear all authentication data
    func clearAllAuthData() {
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
