//
//  TeamDetail.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

public struct TeamDetail: Codable, Hashable, Equatable, Identifiable {
    public static func == (lhs: TeamDetail, rhs: TeamDetail) -> Bool {
        lhs.id == rhs.id
    }

    public let id: String
    public let name: String
    public let code: String
    public let city: String?
    public let founded: Int?
    public let isActive: Bool
    public let arena: Arena?
    public let colors: TeamColors?
    public let logoUrl: String?
    public let websiteUrl: String?
    public let socialMedia: SocialMedia?

    public init(id: String, name: String, code: String, city: String?, founded: Int?, isActive: Bool, arena: Arena?, colors: TeamColors?, logoUrl: String?, websiteUrl: String?, socialMedia: SocialMedia?) {
        self.id = id
        self.name = name
        self.code = code
        self.city = city
        self.founded = founded
        self.isActive = isActive
        self.arena = arena
        self.colors = colors
        self.logoUrl = logoUrl
        self.websiteUrl = websiteUrl
        self.socialMedia = socialMedia
    }

    public static func fakeData() -> TeamDetail {
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

public struct Arena: Codable, Hashable {
    public let name: String
    public let capacity: Int?
    public let city: String?

    public init(name: String, capacity: Int?, city: String?) {
        self.name = name
        self.capacity = capacity
        self.city = city
    }
}

public struct TeamColors: Codable, Hashable {
    public let primary: String
    public let secondary: String?

    public init(primary: String, secondary: String?) {
        self.primary = primary
        self.secondary = secondary
    }
}

public struct SocialMedia: Codable, Hashable {
    public let twitter: String?
    public let facebook: String?
    public let instagram: String?

    public init(twitter: String?, facebook: String?, instagram: String?) {
        self.twitter = twitter
        self.facebook = facebook
        self.instagram = instagram
    }
}
