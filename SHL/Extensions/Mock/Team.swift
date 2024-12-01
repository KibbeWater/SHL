//
//  Team.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 1/12/24.
//

import Foundation
import HockeyKit

extension Team {
    static func fakeData() -> Team {
        Team(
            name: "IK Oskarshamn",
            code: "IKO",
            result: 2
        )
    }
}
