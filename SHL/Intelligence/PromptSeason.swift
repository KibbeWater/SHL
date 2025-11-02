//
//  PromptSeason.swift
//  SHL
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
struct PromptSeason: PromptRepresentable {
    let id: String
    let year: String
    let isCurrent: Bool
    
    let promptRepresentation: Prompt
    
    init(_ season: Season) {
        self.id = season.id
        self.year = season.code
        self.isCurrent = season.isCurrent
        
        self.promptRepresentation = Prompt("")
    }
}
