//
//  journalwidgetControl.swift
//  journalwidget
//
//  Control widget with kind "journalwidget".
//

import AppIntents
import SwiftUI
import WidgetKit

struct journalwidgetControl: ControlWidget {
    static let kind: String = "journalwidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Live Activity",
                isOn: value.isActive,
                action: ToggleLiveActivityIntent(value.isActive == false)
            ) { isActive in
                Label(isActive ? "On" : "Off", systemImage: isActive ? "bolt.fill" : "bolt.slash"
                )
            }
        }
        .displayName("Streak Live Activity")
        .description("Quick toggle for streak Live Activity.")
    }

    struct Value {
        var isActive: Bool
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: ControlConfig) -> Value {
            journalwidgetControl.Value(isActive: false)
        }

        func currentValue(configuration: ControlConfig) async throws -> Value {
            
            return journalwidgetControl.Value(isActive: false)
        }
    }
}

struct ControlConfig: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Control Config"
}

struct ToggleLiveActivityIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Toggle Streak Live Activity"

    @Parameter(title: "Activate")
    var value: Bool

    init() {}

    init(_ activate: Bool) {
        self.value = activate
    }

    func perform() async throws -> some IntentResult {
       
        return .result()
    }
}


