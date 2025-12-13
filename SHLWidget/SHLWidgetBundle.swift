//
//  SHLWidgetBundle.swift
//  SHLWidget
//
//  Created by user242911 on 1/4/24.
//  Updated with new widgets
//

import WidgetKit
import SwiftUI

@main
struct SHLWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Live Activity
        SHLWidgetLiveActivity()

        // Home Screen Widgets
        SHLWidgetUpcoming()
        SHLWidgetStandings()
        SHLWidgetTeamSchedule()
    }
}
