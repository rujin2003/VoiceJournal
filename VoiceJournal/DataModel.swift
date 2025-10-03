//
//  DataModel.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class JournalNote {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String
    var noteContent: String
    var mood: String
    var colorString: String

    init(id: UUID = UUID(), createdAt: Date = Date(), title: String, noteContent: String, mood: String, colorString: String) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.noteContent = noteContent
        self.mood = mood
        self.colorString = colorString
    }

   
    var plainTextPreview: String {
        guard let data = Data(base64Encoded: noteContent),
              let attributedString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) else {
            
            return noteContent
        }
        let fullString = attributedString.string
        return String(fullString.prefix(150))
    }
    

    var color: Color {
        Color.fromString(colorString)
    }
}
