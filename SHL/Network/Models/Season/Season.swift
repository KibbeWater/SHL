//
//  Season.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

struct Season: Codable, Identifiable {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    let isCurrent: Bool
}
