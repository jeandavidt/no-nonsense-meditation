//
//  ContentView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Properties

    @State private var healthKitViewModel = HealthKitViewModel()
    @State private var showHealthKitPermission = false
    @State private var selectedTab = 0

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Timer Tab
            TimerSetupView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(0)

            // Settings Tab
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .sheet(isPresented: $showHealthKitPermission) {
            HealthKitPermissionView(viewModel: healthKitViewModel)
        }
        .task {
            // Check HealthKit authorization on app launch
            await healthKitViewModel.checkAuthorizationStatus()
            showHealthKitPermission = healthKitViewModel.shouldShowPermissionView
        }
        .onChange(of: healthKitViewModel.shouldShowPermissionView) { oldValue, newValue in
            showHealthKitPermission = newValue
        }
        .environment(healthKitViewModel)
    }
}

#Preview {
    ContentView()
}
