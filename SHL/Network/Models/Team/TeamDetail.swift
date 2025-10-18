//
//  TeamDetail.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct TeamDetail: Codable, Identifiable {
    let id: String
    let name: String
    let code: String
    let city: String?
    let founded: Int?
    let isActive: Bool
    let arena: Arena?
    let colors: TeamColors?
    let logoUrl: String?
    let websiteUrl: String?
    let socialMedia: SocialMedia?
}

struct Arena: Codable {
    let name: String
    let capacity: Int?
    let city: String?
}

struct TeamColors: Codable {
    let primary: String
    let secondary: String?
}

struct SocialMedia: Codable {
    let twitter: String?
    let facebook: String?
    let instagram: String?
}
