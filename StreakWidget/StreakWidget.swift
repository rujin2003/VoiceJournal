//
//  StreakWidget.swift
//  StreakWidget
//
//  Dynamic Island presentation for streak Live Activity.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct StreakWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakLiveActivityWidget()
    }
}

struct StreakLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StreakActivityAttributes.self) { context in
            // Lock Screen / Banner
            VStack(alignment: .leading) {
                Text("VoiceJournal")
                    .font(.headline)
                HStack {
                    Text("🔥 Current: \(context.state.currentStreak)")
                    Text("🏆 Best: \(context.state.longestStreak)")
                }
                .font(.subheadline)
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.25))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text("🔥 \(context.state.currentStreak)")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Best")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(context.state.longestStreak)")
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: min(Double(context.state.currentStreak) / Double(max(1, context.state.longestStreak)), 1.0))
                        .tint(.purple)
                }
            } compactLeading: {
                Text("🔥\(context.state.currentStreak)")
            } compactTrailing: {
                Text("🏆\(context.state.longestStreak)")
            } minimal: {
                Text("🔥")
            }
        }
    }
}


