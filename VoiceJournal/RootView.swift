//
//  RootView.swift
//  VoiceJournal
//
//  Observes scene phase and triggers Live Activity when app backgrounds.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \JournalNote.createdAt, order: .reverse) private var notes: [JournalNote]
    @Query private var streaks: [Streak]

    var body: some View {
        ContentView()
    }

    private func triggerStreakLiveActivity() {}
}


