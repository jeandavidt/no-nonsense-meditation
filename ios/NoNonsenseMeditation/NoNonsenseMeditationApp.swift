//
//  NoNonsenseMeditationApp.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

@main
struct NoNonsenseMeditationApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear {
                    UIApplication.shared.beginReceivingRemoteControlEvents()
                }
        }
    }
}
