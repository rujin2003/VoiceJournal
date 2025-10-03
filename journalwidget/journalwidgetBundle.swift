//
//  journalwidgetBundle.swift
//  journalwidget
//
//  Created by Rujin Devkota on 10/3/25.
//

import WidgetKit
import SwiftUI

@main
struct journalwidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakLiveActivityWidget()
        journalwidgetControl()
    }
}
