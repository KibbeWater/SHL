//
//  AdminPairingCoordinator.swift
//  SHL
//

import Foundation
import SwiftUI

@MainActor
final class AdminPairingCoordinator: ObservableObject {
    static let shared = AdminPairingCoordinator()

    enum State: Equatable {
        case idle
        case loadingPreview(code: String)
        case confirming(preview: AdminPreview, code: String)
        case linking(code: String, force: Bool, adminName: String?)
        case alreadyLinked(currentAdminEmail: String?, code: String, adminName: String?)
        case success(adminName: String?)
        case failed(PairingError)
    }

    enum PairingError: Equatable {
        case invalidFormat
        case codeNotFound
        case unauthorized
        case generic(String)

        var message: String {
            switch self {
            case .invalidFormat:
                return "Invalid code. Please ask the admin to regenerate it."
            case .codeNotFound:
                return "This code has expired. Ask the admin to regenerate it."
            case .unauthorized:
                return "You need to sign in again before linking."
            case .generic(let m):
                return m
            }
        }
    }

    @Published private(set) var state: State = .idle
    @Published var isPresented: Bool = false

    private let codeRegex = try! NSRegularExpression(pattern: "^[A-Z0-9]{8}$")

    private init() {}

    func start(rawCode: String) {
        let normalized = rawCode.replacingOccurrences(of: "-", with: "").uppercased()
        let range = NSRange(normalized.startIndex..., in: normalized)
        guard codeRegex.firstMatch(in: normalized, range: range) != nil else {
            state = .failed(.invalidFormat)
            isPresented = true
            return
        }

        state = .loadingPreview(code: normalized)
        isPresented = true

        Task { await fetchPreview(code: normalized) }
    }

    func confirm() {
        guard case .confirming(let preview, let code) = state else { return }
        state = .linking(code: code, force: false, adminName: preview.adminName)
        Task { await performLink(code: code, force: false, adminName: preview.adminName) }
    }

    func confirmReplace() {
        guard case .alreadyLinked(_, let code, let adminName) = state else { return }
        state = .linking(code: code, force: true, adminName: adminName)
        Task { await performLink(code: code, force: true, adminName: adminName) }
    }

    func cancel() {
        state = .idle
        isPresented = false
    }

    private func fetchPreview(code: String) async {
        do {
            let preview = try await SHLAPIClient.shared.getAdminLinkPreview(code: code)
            state = .confirming(preview: preview, code: code)
        } catch {
            state = .failed(mapError(error))
        }
    }

    private func performLink(code: String, force: Bool, adminName: String?) async {
        do {
            try await SHLAPIClient.shared.linkAdmin(code: code, force: force)
            state = .success(adminName: adminName)
        } catch SHLAPIError.httpError(409, let data) {
            let body = data.flatMap { try? JSONDecoder().decode(LinkAdminConflictBody.self, from: $0) }
            state = .alreadyLinked(
                currentAdminEmail: body?.currentAdminEmail,
                code: code,
                adminName: adminName
            )
        } catch {
            state = .failed(mapError(error))
        }
    }

    private func mapError(_ error: Error) -> PairingError {
        if let apiError = error as? SHLAPIError {
            switch apiError {
            case .unauthorized:
                return .unauthorized
            case .httpError(400, let data), .httpError(404, let data):
                let body = data.flatMap { try? JSONDecoder().decode(ApiErrorBody.self, from: $0) }
                switch body?.error {
                case "INVALID_CODE_FORMAT": return .invalidFormat
                case "LINK_CODE_NOT_FOUND": return .codeNotFound
                default:
                    return .generic(body?.message ?? apiError.errorDescription ?? "Something went wrong.")
                }
            default:
                return .generic(apiError.errorDescription ?? "Something went wrong.")
            }
        }
        return .generic(error.localizedDescription)
    }
}
