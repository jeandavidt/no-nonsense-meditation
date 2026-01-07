//
//  MeditationAppShortcuts.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-06.
//

import AppIntents

/// App Shortcuts provider for meditation intents
/// Registers all available Siri shortcuts for the meditation app
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
struct MeditationAppShortcuts: AppShortcutsProvider {

    // MARK: - App Shortcuts

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartMeditationIntent(),
            phrases: [
                "Start meditation in \(.applicationName)",
                "Begin meditation with \(.applicationName)"
            ],
            shortTitle: "Start Meditation",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: PauseMeditationIntent(),
            phrases: [
                "Pause meditation in \(.applicationName)",
                "Pause my meditation in \(.applicationName)"
            ],
            shortTitle: "Pause Meditation",
            systemImageName: "pause.circle"
        )

        AppShortcut(
            intent: ResumeMeditationIntent(),
            phrases: [
                "Resume meditation in \(.applicationName)",
                "Continue meditation in \(.applicationName)",
                "Resume my meditation in \(.applicationName)"
            ],
            shortTitle: "Resume Meditation",
            systemImageName: "play.circle"
        )

        AppShortcut(
            intent: StopMeditationIntent(),
            phrases: [
                "Stop meditation in \(.applicationName)",
                "End meditation in \(.applicationName)",
                "Finish my meditation in \(.applicationName)"
            ],
            shortTitle: "Stop Meditation",
            systemImageName: "stop.circle"
        )
    }
}
