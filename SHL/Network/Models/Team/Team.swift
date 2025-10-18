//
//  Team.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Team: Codable, Identifiable {
    let id: String
    let name: String
    let code: String
    let city: String?
    let founded: Int?
    let isActive: Bool
}
