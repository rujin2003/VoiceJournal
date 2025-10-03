//
//  VoiceJournalApp.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import SwiftUI
import SwiftData

@main
struct VoiceJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: JournalNote.self)
    }
}
