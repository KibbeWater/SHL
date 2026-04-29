//
//  AdminPairingSheet.swift
//  SHL
//

import SwiftUI

struct AdminPairingSheet: View {
    @EnvironmentObject var coord: AdminPairingCoordinator

    var body: some View {
        NavigationStack {
            Group {
                switch coord.state {
                case .idle:
                    EmptyView()
                case .loadingPreview:
                    LoadingContent(message: "Verifying code…")
                case .confirming(let preview, _):
                    ConfirmContent(preview: preview, onConfirm: coord.confirm, onCancel: coord.cancel)
                case .linking:
                    LoadingContent(message: "Linking…")
                case .alreadyLinked(let email, _, _):
                    ReplaceContent(currentEmail: email, onReplace: coord.confirmReplace, onCancel: coord.cancel)
                case .success(let name):
                    SuccessContent(adminName: name, onDone: coord.cancel)
                case .failed(let err):
                    ErrorContent(error: err, onDone: coord.cancel)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isInFlight)
    }

    private var isInFlight: Bool {
        switch coord.state {
        case .loadingPreview, .linking: return true
        default: return false
        }
    }
}

// MARK: - Sub-views

private struct LoadingContent: View {
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text(message)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ConfirmContent: View {
    let preview: AdminPreview
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .padding(.top, 8)

            Text("Link this device?")
                .font(.title2.bold())

            VStack(spacing: 4) {
                Text(preview.adminName)
                    .font(.headline)
                Text(preview.adminEmail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Test push notifications from the admin dashboard will be delivered to this device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("Link Device")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Cancel", role: .cancel, action: onCancel)
                    .controlSize(.large)
            }
        }
    }
}

private struct ReplaceContent: View {
    let currentEmail: String?
    let onReplace: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .padding(.top, 8)

            Text("Device Already Linked")
                .font(.title2.bold())

            if let email = currentEmail {
                Text("This device is currently linked to \(email).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("This device is currently linked to another admin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("Do you want to replace the existing link?")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button(role: .destructive, action: onReplace) {
                    Text("Replace Link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Cancel", role: .cancel, action: onCancel)
                    .controlSize(.large)
            }
        }
    }
}

private struct SuccessContent: View {
    let adminName: String?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .padding(.top, 8)

            Text("Device Linked")
                .font(.title2.bold())

            if let name = adminName {
                Text("Linked to \(name).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

private struct ErrorContent: View {
    let error: AdminPairingCoordinator.PairingError
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
                .padding(.top, 8)

            Text("Couldn't Link")
                .font(.title2.bold())

            Text(error.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button(action: onDone) {
                Text("Close")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
}
