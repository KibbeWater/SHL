//
//  GameExtensions.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 27/9/24.
//

import Foundation
import HockeyKit

extension Game {
    func formatDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }
    
    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
