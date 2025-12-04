//
//  Season.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
import FoundationModels

struct Season: Codable, Identifiable {
    let id: String
    let externalUUID: String
    let code: String
    let name: String
    let startDate: Date?
    let endDate: Date?
    let isCurrent: Bool
}
