//
//  iCloudSyncManager.swift
//  SHL
//
//  Created by Claude Code
//

import Foundation
import CloudKit

/// Manager for syncing user authentication state across devices using iCloud
final class iCloudSyncManager {
    static let shared = iCloudSyncManager()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // Record type for user session
    private let userSessionRecordType = "UserSession"
    private let userSessionRecordID = "current_user_session"

    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - iCloud Availability

    /// Check if iCloud is available
    func checkiCloudAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            print("iCloud availability check failed: \(error)")
            return false
        }
    }

    // MARK: - User Session Sync

    /// Save user session to iCloud
    func saveUserSession(userId: String, token: String, expiresAt: Date) async throws {
        let recordID = CKRecord.ID(recordName: userSessionRecordID)
        let record = CKRecord(recordType: userSessionRecordType, recordID: recordID)

        record["userId"] = userId as CKRecordValue
        record["token"] = token as CKRecordValue
        record["expiresAt"] = expiresAt as CKRecordValue
        record["lastUpdated"] = Date() as CKRecordValue

        do {
            _ = try await privateDatabase.save(record)
            print("User session saved to iCloud")
        } catch let error as CKError {
            switch error.code {
            case .quotaExceeded:
                print("iCloud quota exceeded, cannot sync user session")
                // Post notification to inform user
                NotificationCenter.default.post(name: .iCloudQuotaExceeded, object: nil)
            case .notAuthenticated:
                print("iCloud not signed in, cannot sync user session")
                // Post notification to prompt user
                NotificationCenter.default.post(name: .iCloudNotAuthenticated, object: nil)
            default:
                print("CloudKit error saving user session: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Failed to save user session to iCloud: \(error)")
            throw error
        }
    }

    /// Fetch user session from iCloud
    func fetchUserSession() async throws -> (userId: String, token: String, expiresAt: Date)? {
        let recordID = CKRecord.ID(recordName: userSessionRecordID)

        do {
            let record = try await privateDatabase.record(for: recordID)

            guard let userId = record["userId"] as? String,
                  let token = record["token"] as? String,
                  let expiresAt = record["expiresAt"] as? Date else {
                print("User session record is missing required fields")
                return nil
            }

            return (userId: userId, token: token, expiresAt: expiresAt)
        } catch let error as CKError {
            switch error.code {
            case .unknownItem:
                // No session exists in iCloud
                return nil
            case .notAuthenticated:
                print("iCloud not signed in, cannot fetch user session")
                NotificationCenter.default.post(name: .iCloudNotAuthenticated, object: nil)
                throw error
            default:
                print("CloudKit error fetching user session: \(error.localizedDescription)")
                throw error
            }
        } catch {
            print("Failed to fetch user session from iCloud: \(error)")
            throw error
        }
    }

    /// Delete user session from iCloud
    func deleteUserSession() async throws {
        let recordID = CKRecord.ID(recordName: userSessionRecordID)

        do {
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            print("User session deleted from iCloud")
        } catch let error as CKError {
            switch error.code {
            case .unknownItem:
                // Already deleted, no action needed
                print("User session was already deleted from iCloud")
            case .notAuthenticated:
                print("iCloud not signed in, cannot delete user session")
                NotificationCenter.default.post(name: .iCloudNotAuthenticated, object: nil)
                throw error
            default:
                print("CloudKit error deleting user session: \(error.localizedDescription)")
                throw error
            }
        } catch {
            print("Failed to delete user session from iCloud: \(error)")
            throw error
        }
    }

    // MARK: - User Opt-In Status Sync

    /// Save user opt-in status to iCloud (using NSUbiquitousKeyValueStore)
    func saveOptInStatus(_ optedIn: Bool) {
        let store = NSUbiquitousKeyValueStore.default
        store.set(optedIn, forKey: "userManagementOptIn")
        store.synchronize()
    }

    /// Get user opt-in status from iCloud
    func getOptInStatus() -> Bool? {
        let store = NSUbiquitousKeyValueStore.default

        // Check if value exists
        if store.object(forKey: "userManagementOptIn") != nil {
            return store.bool(forKey: "userManagementOptIn")
        }
        return nil
    }

    // MARK: - Notification Preferences Sync

    /// Save notification preferences to iCloud
    func saveNotificationPreferences(_ settings: NotificationSettings) {
        let store = NSUbiquitousKeyValueStore.default

        if let encoded = try? JSONEncoder().encode(settings) {
            store.set(encoded, forKey: "notificationPreferences")
            store.synchronize()
        }
    }

    /// Get notification preferences from iCloud
    func getNotificationPreferences() -> NotificationSettings? {
        let store = NSUbiquitousKeyValueStore.default

        guard let data = store.data(forKey: "notificationPreferences"),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return nil
        }

        return settings
    }
}
