//
//  Series.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Series: Codable, Identifiable {
    let id: String
    let name: String
    let type: String // "regular", "playoffs", etc.
    let seasonId: String
    let isCurrent: Bool
}
