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
    @State private var showPersistenceWarning = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear {
                    UIApplication.shared.beginReceivingRemoteControlEvents()

                    // Show warning if in degraded persistence mode
                    if case .inMemory = persistenceController.persistenceMode {
                        showPersistenceWarning = true
                    }
                }
                .alert("Storage Notice", isPresented: $showPersistenceWarning) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(persistenceController.statusMessage + "\n\n" +
                         (persistenceController.lastError?.recoverySuggestion ?? ""))
                }
        }
    }
}
