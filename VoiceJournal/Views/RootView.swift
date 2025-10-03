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
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @Query(sort: \JournalNote.createdAt, order: .reverse) private var notes: [JournalNote]
    @Query private var streaks: [Streak]

    var body: some View {
        Group {
            if hasSeenOnboarding {
                ContentView()
            } else {
                SplashScreen()
            }
        }
    }

    private func triggerStreakLiveActivity() {}
}


