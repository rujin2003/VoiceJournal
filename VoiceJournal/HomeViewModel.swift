//
//  HomeViewModel.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import SwiftUI

struct JournalEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let title: String
    let content: String
    let mood: String
    let color: Color

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

class HomeViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var currentStreak: Int = 12
    @Published var longestStreak: Int = 45
    @Published var totalEntries: Int = 8
    
    var allDatesFromToday: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let entryDates = Set(entries.map { calendar.startOfDay(for: $0.date) })
        
        var allDates: Set<Date> = [today]
        for i in 1...90 {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
                allDates.insert(pastDate)
            }
        }
        
        allDates.formUnion(entryDates)
        
        return Array(allDates).sorted(by: >)
    }
    
    func hasEntries(for date: Date) -> Bool {
        let calendar = Calendar.current
        return entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func entriesForDate(_ date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    init() {
        var tempEntries: [JournalEntry] = []
        let moods = ["😊", "😢", "😠", "🤩", "😐", "🥰", "😎", "🤔"]

        let oct3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 3))!
        let oct2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 2))!
        let sept25 = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 25))!
        
        tempEntries.append(JournalEntry(
            date: oct3,
            title: "Morning Reflection",
            content: "Woke up feeling refreshed and ready to tackle the day.",
            mood: moods.randomElement()!,
            color: Color.journalColors.randomElement()!
        ))
        
        tempEntries.append(JournalEntry(
            date: oct3,
            title: "Evening Thoughts",
            content: "Today was productive. Got a lot of things done and felt positive.",
            mood: moods.randomElement()!,
            color: Color.journalColors.randomElement()!
        ))

        tempEntries.append(JournalEntry(
            date: oct2,
            title: "A Calm Day",
            content: "Not much happened today, but I enjoyed the peaceful vibes.",
            mood: moods.randomElement()!,
            color: Color.journalColors.randomElement()!
        ))
        
        for i in 1...5 {
            tempEntries.append(JournalEntry(
                date: sept25,
                title: "Sept 25 Entry #\(i)",
                content: "Journal entry number \(i) for Sept 25. Writing down some random reflections.",
                mood: moods.randomElement()!,
                color: Color.journalColors.randomElement()!
            ))
        }
        
        self.entries = tempEntries
    }
}
