//
//  LiveActivityManager.swift
//  VoiceJournal
//
//  Starts and ends the streak Live Activity.
//

import Foundation
import ActivityKit

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<StreakActivityAttributes>?
    private var lastContentState: StreakActivityAttributes.ContentState?

    func startStreakActivity(currentStreak: Int, longestStreak: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = StreakActivityAttributes(title: "VoiceJournal")
        let initialState = StreakActivityAttributes.ContentState(
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )

        do {
            activity = try Activity.request(attributes: attributes, contentState: initialState)
            lastContentState = initialState
        } catch {
            print("Failed to start activity: \(error)")
        }
    }

    func updateStreakActivity(currentStreak: Int? = nil, longestStreak: Int? = nil) {
        guard let activity else { return }

        let updatedState = StreakActivityAttributes.ContentState(
            currentStreak: currentStreak ?? lastContentState?.currentStreak ?? 0,
            longestStreak: longestStreak ?? lastContentState?.longestStreak ?? 0
        )
        lastContentState = updatedState

        Task {
            await activity.update(using: updatedState)
        }
    }

    func endStreakActivity(after seconds: TimeInterval = 10) {
        guard let activity else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            Task { [weak self] in
                await activity.end(dismissalPolicy: .immediate)
                self?.activity = nil
                self?.lastContentState = nil
            }
        }
    }
}


