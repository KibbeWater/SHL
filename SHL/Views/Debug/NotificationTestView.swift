//
//  NotificationTestView.swift
//  SHL
//
//  Created by Claude Code
//

#if DEBUG
import SwiftUI

struct NotificationTestView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var pushManager = PushNotificationManager.shared

    @State private var selectedType: NotificationType = .custom
    @State private var customTitle: String = "Test Notification"
    @State private var customBody: String = "This is a test notification"
    @State private var isLoading = false
    @State private var showResult = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""

    var body: some View {
        List {
            // Notification Type Section
            Section {
                Picker("Notification Type", selection: $selectedType) {
                    ForEach(NotificationType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Notification Type")
            }

            // Custom Notification Fields
            if selectedType == .custom {
                Section {
                    TextField("Title", text: $customTitle)
                    TextField("Body", text: $customBody)
                } header: {
                    Text("Custom Content")
                } footer: {
                    Text("Enter a custom title and message for your test notification")
                }
            }

            // Send Button Section
            Section {
                Button(action: sendTestNotification) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Label(
                            isLoading ? "Sending..." : "Send Test Notification",
                            systemImage: "paperplane.fill"
                        )
                    }
                }
                .disabled(isLoading || !canSendNotification)
            }

            // Status & Info Section
            Section {
                if !authManager.isAuthenticated {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Not authenticated")
                    }
                } else if authManager.currentUserId == nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("No user ID available")
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Ready to send")
                    }
                }

                if let userId = authManager.currentUserId {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(userId)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .textSelection(.enabled)
                    }
                }
            } header: {
                Text("Status")
            }

            // Help Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("How it works")
                            .font(.headline)
                    }

                    Text("This sends a test notification to all your registered devices using your authentication token.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Test notifications bypass your notification preferences to ensure delivery.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Test Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert(resultTitle, isPresented: $showResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
    }

    private var canSendNotification: Bool {
        guard authManager.isAuthenticated,
              let _ = authManager.currentUserId else {
            return false
        }

        if selectedType == .custom {
            return !customTitle.isEmpty && !customBody.isEmpty
        }

        return true
    }

    private func sendTestNotification() {
        isLoading = true

        Task {
            do {
                // Build request
                let request: TestNotificationRequest
                if selectedType == .custom {
                    request = TestNotificationRequest(
                        type: .custom,
                        title: customTitle,
                        body: customBody
                    )
                } else {
                    request = TestNotificationRequest(type: selectedType)
                }

                // Send test notification - backend uses JWT to identify user
                let response = try await SHLAPIClient.shared.testNotification(
                    request: request
                )

                await MainActor.run {
                    isLoading = false
                    handleSuccess(response: response)
                }
            } catch let error as SHLAPIError {
                await MainActor.run {
                    isLoading = false
                    let errorMsg = error.errorDescription ?? "Unknown error occurred"
                    var details = ""

                    // Add more details for debugging
                    if case .httpError(let statusCode, let data) = error {
                        details = "HTTP Status: \(statusCode)"
                        if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                            details += "\nResponse: \(responseStr)"
                        }
                    }

                    showError(message: errorMsg, details: details.isEmpty ? nil : details)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(message: error.localizedDescription, details: "\(error)")
                }
            }
        }
    }

    private func handleSuccess(response: TestNotificationResponse) {
        resultTitle = response.isFullSuccess ? "Success" : "Partial Success"

        var message = response.summary + "\n\n"

        if !response.isFullSuccess {
            message += "Details:\n"
            for result in response.results {
                let status = result.success ? "✓" : "✗"
                let env = result.environment
                message += "\(status) \(env)"
                if let error = result.error {
                    message += ": \(error)"
                }
                message += "\n"
            }
        }

        resultMessage = message
        showResult = true
    }

    private func showError(message: String, details: String? = nil) {
        resultTitle = "Error"
        var fullMessage = message

        if let details = details {
            fullMessage += "\n\nDetails:\n\(details)"
        }

        resultMessage = fullMessage
        showResult = true

        #if DEBUG
        print("❌ Error shown to user: \(fullMessage)")
        #endif
    }
}

#Preview {
    NavigationStack {
        NotificationTestView()
    }
}
#endif
