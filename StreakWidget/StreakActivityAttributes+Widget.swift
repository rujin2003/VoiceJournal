//
//  StreakActivityAttributes+Widget.swift
//  StreakWidget
//
//  Duplicate attributes for the widget extension target.
//

import Foundation
import ActivityKit

struct StreakActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentStreak: Int
        var longestStreak: Int
    }

    var title: String
}


