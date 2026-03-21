//
//  AuthenticationManager.swift
//  SHLNetwork
//
//  Created by Claude Code
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Manager for handling user authentication with multi-device iCloud sync support
@MainActor
public final class AuthenticationManager: ObservableObject {
    public static let shared: AuthenticationManager = {
        let manager = AuthenticationManager()
        // Register self as auth provider on the shared API client
        SHLAPIClient.shared.setAuthProvider(manager)
        return manager
    }()

    @Published public var isAuthenticated = false
    @Published public var currentUserId: String?
    @Published public var userProfile: UserProfile?

    private let keychain = KeychainManager.shared
    private let iCloudSync = iCloudSyncManager.shared

    private init() {
        // Load authentication state on init
        loadAuthenticationState()
    }

    // MARK: - Authentication State

    /// Check if user is currently authenticated
    public var hasValidToken: Bool {
        guard let token = keychain.getToken(),
              !token.isEmpty else {
            return false
        }

        // Check if token is expired
        return !keychain.isTokenExpiringSoon()
    }

    /// Get current JWT token
    public var currentToken: String? {
        return keychain.getToken()
    }

    // MARK: - Registration & Login

    /// Register or login user (device-based, idempotent)
    public func register() async throws -> String {
        let request = buildAuthRequest()

        do {
            let response: AuthResponse = try await SHLAPIClient.shared.request(
                endpoint: "/auth/register",
                method: HTTPMethod.post,
                body: request
            )

            // Save authentication data
            try await saveAuthenticationData(response)

            // Update state
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUserId = response.userId
            }

            return response.userId
        } catch {
            print("Registration failed: \(error)")
            throw error
        }
    }

    /// Refresh JWT token
    public func refreshToken() async throws {
        guard hasValidToken else {
            throw AuthError.noValidToken
        }

        do {
            let response: TokenRefreshResponse = try await SHLAPIClient.shared.request(
                endpoint: "/auth/refresh",
                method: HTTPMethod.post,
                requiresAuth: true
            )

            // Save new token
            keychain.saveToken(response.token, expiresAt: response.expiresAt)

            // Sync to iCloud
            try? await iCloudSync.saveUserSession(
                userId: response.userId,
                token: response.token,
                expiresAt: response.expiresAt
            )

            print("Token refreshed successfully")
        } catch {
            print("Token refresh failed: \(error)")
            throw error
        }
    }

    /// Logout user (invalidate token)
    public func logout() async throws {
        do {
            // Call logout endpoint to invalidate token
            let _: EmptyResponse = try await SHLAPIClient.shared.request(
                endpoint: "/auth/logout",
                method: HTTPMethod.post,
                requiresAuth: true
            )
        } catch {
            print("Logout API call failed: \(error)")
            // Continue with local logout even if API fails
        }

        // Clear local authentication data
        clearAuthenticationData()

        // Delete from iCloud
        try? await iCloudSync.deleteUserSession()

        await MainActor.run {
            self.isAuthenticated = false
            self.currentUserId = nil
            self.userProfile = nil
        }
    }

    // MARK: - User Profile

    /// Fetch user profile from backend
    public func fetchUserProfile() async throws -> UserProfile {
        do {
            let profile: UserProfile = try await SHLAPIClient.shared.request(
                endpoint: "/user/profile",
                method: HTTPMethod.get,
                requiresAuth: true
            )

            await MainActor.run {
                self.userProfile = profile
            }

            return profile
        } catch {
            print("Failed to fetch user profile: \(error)")
            throw error
        }
    }

    // MARK: - Multi-Device Sync

    /// Check iCloud for existing user session
    public func syncWithiCloud() async throws -> Bool {
        // Check if iCloud is available
        guard await iCloudSync.checkiCloudAvailability() else {
            print("iCloud is not available")
            return false
        }

        // Try to fetch existing session
        if let session = try? await iCloudSync.fetchUserSession() {
            // Check if session is still valid
            guard session.expiresAt > Date() else {
                print("iCloud session is expired")
                return false
            }

            // Save to local keychain
            keychain.saveToken(session.token, expiresAt: session.expiresAt)
            keychain.saveUserId(session.userId)

            // Validate session with backend by trying to refresh
            do {
                try await refreshToken()
                #if DEBUG
                print("Successfully validated iCloud session with backend")
                #endif
            } catch {
                #if DEBUG
                print("iCloud session invalid on backend, clearing and re-registering")
                #endif
                // Session is invalid (user doesn't exist), clear and return false
                clearAuthenticationData()
                try? await iCloudSync.deleteUserSession()
                return false
            }

            await MainActor.run {
                self.isAuthenticated = true
                self.currentUserId = session.userId
            }

            print("Successfully synced with iCloud session")
            return true
        }

        return false
    }

    /// Save current session to iCloud
    private func saveSessionToiCloud() async throws {
        guard let token = keychain.getToken(),
              let userId = keychain.getUserId(),
              let expiresAt = keychain.getTokenExpiresAt() else {
            return
        }

        try await iCloudSync.saveUserSession(
            userId: userId,
            token: token,
            expiresAt: expiresAt
        )
    }

    // MARK: - Account Management

    /// Delete user account (GDPR compliance)
    public func deleteAccount() async throws {
        do {
            let _: EmptyResponse = try await SHLAPIClient.shared.request(
                endpoint: "/user",
                method: HTTPMethod.delete,
                requiresAuth: true
            )

            // Clear all data
            clearAuthenticationData()
            try? await iCloudSync.deleteUserSession()

            await MainActor.run {
                self.isAuthenticated = false
                self.currentUserId = nil
                self.userProfile = nil
            }

            print("Account deleted successfully")
        } catch {
            print("Account deletion failed: \(error)")
            throw error
        }
    }

    /// Export user data (GDPR compliance)
    public func exportUserData() async throws -> UserDataExport {
        do {
            let data: UserDataExport = try await SHLAPIClient.shared.request(
                endpoint: "/user/export",
                method: HTTPMethod.get,
                requiresAuth: true
            )
            return data
        } catch {
            print("User data export failed: \(error)")
            throw error
        }
    }

    // MARK: - Helper Methods

    private func buildAuthRequest() -> AuthRequest {
        #if canImport(UIKit)
        let deviceModel = UIDevice.modelIdentifier
        let iosVersion = UIDevice.current.systemVersion
        #else
        let deviceModel = "Unknown"
        let iosVersion = "Unknown"
        #endif

        return AuthRequest(
            deviceId: keychain.getDeviceId(),
            fallbackDeviceId: keychain.getFallbackDeviceId(),
            deviceModel: deviceModel,
            iosVersion: iosVersion,
            appVersion: Bundle.main.appVersion
        )
    }

    private func saveAuthenticationData(_ response: AuthResponse) async throws {
        // Save to keychain
        keychain.saveToken(response.token, expiresAt: response.expiresAt)
        keychain.saveUserId(response.userId)

        // Sync to iCloud
        try? await iCloudSync.saveUserSession(
            userId: response.userId,
            token: response.token,
            expiresAt: response.expiresAt
        )
    }

    private func loadAuthenticationState() {
        if let userId = keychain.getUserId(), hasValidToken {
            isAuthenticated = true
            currentUserId = userId
        }
    }

    private func clearAuthenticationData() {
        keychain.clearAllAuthData()
    }
}

// MARK: - AuthenticationProviding Conformance

extension AuthenticationManager: AuthenticationProviding {}

// MARK: - Auth Errors

public enum AuthError: LocalizedError {
    case noValidToken
    case invalidExpirationDate
    case registrationFailed
    case tokenRefreshFailed
    case iCloudUnavailable

    public var errorDescription: String? {
        switch self {
        case .noValidToken:
            return "No valid authentication token found"
        case .invalidExpirationDate:
            return "Invalid token expiration date"
        case .registrationFailed:
            return "User registration failed"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .iCloudUnavailable:
            return "iCloud is not available"
        }
    }
}
