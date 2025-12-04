//
//  SHLAPIDebug.swift
//  SHL
//

import Foundation

#if DEBUG
extension SHLAPIClient {
    /// Test push notifications (Debug Only)
    /// Uses JWT authentication to identify the user automatically
    func testNotification(request: TestNotificationRequest) async throws -> TestNotificationResponse {
        // Debug logging
        print("\n========== TEST NOTIFICATION REQUEST ==========")
        print("URL: https://api.lrlnet.se/api/v1/test-notification")
        print("Method: POST")

        if let requestData = try? JSONEncoder().encode(request),
           let requestJSON = String(data: requestData, encoding: .utf8) {
            print("Request Body: \(requestJSON)")
        }

        if let token = KeychainManager.shared.getToken() {
            let tokenPreview = String(token.prefix(10)) + "..." + String(token.suffix(10))
            print("JWT Token: \(tokenPreview)")
        }

        print("================================================\n")

        do {
            let response: TestNotificationResponse = try await self.request(
                endpoint: "/test-notification",
                method: .post,
                body: request,
                requiresAuth: true
            )
            print("✅ Test notification sent successfully")
            return response
        } catch {
            print("❌ Test notification failed: \(error)")
            throw error
        }
    }
}
#endif
