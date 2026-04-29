//
//  AdminPairingModels.swift
//  SHL
//

import Foundation

struct AdminPreview: Decodable, Equatable {
    let adminName: String
    let adminEmail: String
    let expiresAt: Date
}

struct LinkAdminRequest: Encodable {
    let code: String
    let force: Bool?
}

struct LinkAdminConflictBody: Decodable {
    let error: String?
    let currentAdminEmail: String?
}

struct ApiErrorBody: Decodable {
    let error: String?
    let message: String?
}
