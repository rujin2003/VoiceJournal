//
//  HomeViewModel.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//
import SwiftUI

// MARK: - Data Model
struct JournalEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let title: String
    let content: String
    let mood: String
    
    var color: Color {
        switch mood {
            case "😊": return .green
            case "😢": return .blue
            case "😠": return .red
            case "🤩": return .yellow
            case "😐": return .gray
            default: return .purple
        }
    }
}

class HomeViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var currentStreak: Int = 12
    @Published var longestStreak: Int = 45
    @Published var totalEntries: Int = 128
    
    init() {
        var tempEntries: [JournalEntry] = []
        let moods = ["😊", "😢", "😠", "🤩", "😐"]
        for i in 0..<50 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            tempEntries.append(
                JournalEntry(
                    date: date,
                    title: "Day \(50 - i) Thoughts",
                    content: "This is a sample journal entry content. It describes the feelings and events of the day.",
                    mood: moods.randomElement()!
                )
            )
        }
        self.entries = tempEntries
    }
}
