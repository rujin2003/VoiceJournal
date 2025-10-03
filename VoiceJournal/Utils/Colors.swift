//
//  Colors.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//
import SwiftUI



extension Color {
    static let appBackground = Color.white
    static let appBackgroundStart = Color(red: 0.95, green: 0.92, blue: 1.0)
    static let appBackgroundEnd = Color(red: 0.88, green: 0.9, blue: 0.98)

    
    static let vibrantPurple = Color(red: 0.4, green: 0.2, blue: 0.8)
    static let vibrantOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    static let vibrantGold = Color(red: 1.0, green: 0.75, blue: 0.0)
    static let vibrantTeal = Color(red: 0.1, green: 0.6, blue: 0.55)
    
    
    static let journalColors: [Color] = [.vibrantPurple, .vibrantOrange, .vibrantGold, .vibrantTeal]
    
    
    static func fromString(_ colorString: String) -> Color {
        switch colorString {
        case "vibrantPurple": return .vibrantPurple
        case "vibrantOrange": return .vibrantOrange
        case "vibrantGold": return .vibrantGold
        case "vibrantTeal": return .vibrantTeal
        default: return .gray
        }
    }

    var description: String {
        switch self {
        case .vibrantPurple: return "vibrantPurple"
        case .vibrantOrange: return "vibrantOrange"
        case .vibrantGold: return "vibrantGold"
        case .vibrantTeal: return "vibrantTeal"
        default: return "gray"
        }
    }
}

import Foundation
extension Notification.Name {
    static let journalSaved = Notification.Name("journalSaved")
}
