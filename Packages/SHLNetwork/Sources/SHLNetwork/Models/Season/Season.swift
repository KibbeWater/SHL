//
//  Season.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public struct Season: Codable, Identifiable {
    public let id: String
    public let externalUUID: String
    public let code: String
    public let name: String
    public let startDate: Date?
    public let endDate: Date?
    public let isCurrent: Bool

    public init(id: String, externalUUID: String, code: String, name: String, startDate: Date?, endDate: Date?, isCurrent: Bool) {
        self.id = id
        self.externalUUID = externalUUID
        self.code = code
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isCurrent = isCurrent
    }
}
