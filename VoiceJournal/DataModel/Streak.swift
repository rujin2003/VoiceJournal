//
//  Streak.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import Foundation
import SwiftData

@Model
class Streak {
    var numberOfEntries: Int
    var longestStreak: Int
    var currentStreak: Int
    var lastEntryDate: Date?

    init(numberOfEntries: Int = 0, longestStreak: Int = 0, currentStreak: Int = 0, lastEntryDate: Date? = nil) {
        self.numberOfEntries = numberOfEntries
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.lastEntryDate = lastEntryDate
    }
}
