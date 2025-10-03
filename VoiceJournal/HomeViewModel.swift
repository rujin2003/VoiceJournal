//
//  HomeViewModel.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import SwiftUI
import SwiftUI
import Foundation

class HomeViewModel: ObservableObject {
    @Published var currentStreak: Int = 12
    @Published var longestStreak: Int = 45

    func totalEntries(from notes: [JournalNote]) -> Int {
        notes.count
    }

    func allDatesFromToday(from notes: [JournalNote]) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let entryDates = Set(notes.map { calendar.startOfDay(for: $0.createdAt) })
        
        var allDates: Set<Date> = [today]
        for i in 1...90 {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
                allDates.insert(pastDate)
            }
        }
        allDates.formUnion(entryDates)
        return Array(allDates).sorted(by: >)
    }
    
    func hasEntries(for date: Date, in notes: [JournalNote]) -> Bool {
        let calendar = Calendar.current
        return notes.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }
    
    func entriesForDate(_ date: Date, in notes: [JournalNote]) -> [JournalNote] {
        let calendar = Calendar.current
        return notes.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
