//
//  StreakActivityAttributes.swift
//  VoiceJournal
//
//  Defines Live Activity attributes and state for displaying streaks.
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


