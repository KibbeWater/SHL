//
//  TeamDetail.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct TeamDetail: Codable, Hashable, Equatable, Identifiable {
    static func == (lhs: TeamDetail, rhs: TeamDetail) -> Bool {
        lhs.id == rhs.id
    }

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

    static func fakeData() -> TeamDetail {
        TeamDetail(
            id: "team-1",
            name: "IK Oskarshamn",
            code: "IKO",
            city: "Oskarshamn",
            founded: 1970,
            isActive: true,
            arena: Arena(name: "Be-Ge Hockey Center", capacity: 3275, city: "Oskarshamn"),
            colors: TeamColors(primary: "#003087", secondary: "#FFD700"),
            logoUrl: nil,
            websiteUrl: "https://www.ikoskarshamn.se",
            socialMedia: SocialMedia(twitter: "@IKOskarshamn", facebook: nil, instagram: "@ikoskarshamn")
        )
    }
}

struct Arena: Codable, Hashable {
    let name: String
    let capacity: Int?
    let city: String?
}

struct TeamColors: Codable, Hashable {
    let primary: String
    let secondary: String?
}

struct SocialMedia: Codable, Hashable {
    let twitter: String?
    let facebook: String?
    let instagram: String?
}
