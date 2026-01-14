//
//  StatisticsViewModel.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-08.
//

import Foundation
import Observation

/// ViewModel for managing meditation statistics display
@Observable
@MainActor
class StatisticsViewModel {

    // MARK: - Types

    enum DataSourceMode: String, CaseIterable, Identifiable {
        case inApp = "This App"
        case allApps = "All Apps"

        var id: String { rawValue }
    }

    // MARK: - Properties

    /// Current data source mode
    private(set) var dataSourceMode: DataSourceMode = .inApp

    /// Current statistics
    private(set) var statistics: SessionStatistics = .empty

    /// Loading state
    private(set) var isLoading: Bool = false

    /// Error state
    private(set) var error: Error?

    /// Whether HealthKit mode is available
    private(set) var isHealthKitAvailable: Bool = false

    // MARK: - Dependencies

    private let coreDataSource: MeditationDataSource
    private let healthKitSource: MeditationDataSource
    private let healthKitService: HealthKitService

    // MARK: - Initialization

    init(
        coreDataSource: MeditationDataSource = CoreDataMeditationDataSource(),
        healthKitSource: MeditationDataSource = HealthKitMeditationDataSource(),
        healthKitService: HealthKitService = HealthKitService()
    ) {
        self.coreDataSource = coreDataSource
        self.healthKitSource = healthKitSource
        self.healthKitService = healthKitService

        // Load saved preference
        if let savedMode = UserDefaults.standard.string(forKey: "StatisticsDataSourceMode"),
           let mode = DataSourceMode(rawValue: savedMode) {
            self.dataSourceMode = mode
        }
    }

    // MARK: - Public Methods

    /// Check if HealthKit is available and authorized
    func checkHealthKitAvailability() async {
        let authStatus = await healthKitService.checkAuthorizationStatus()
        isHealthKitAvailable = (authStatus == .authorized)

        // If HealthKit not available and currently in All Apps mode, switch to This App
        if !isHealthKitAvailable && dataSourceMode == .allApps {
            dataSourceMode = .inApp
            saveDataSourceMode()
        }
    }

    /// Load statistics for current data source mode
    func loadStatistics() async {
        isLoading = true
        error = nil

        do {
            let source = currentDataSource()
            statistics = try await source.calculateStatistics()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            statistics = .empty
        }
    }

    /// Load focus-specific statistics
    func loadFocusStatistics() async {
        isLoading = true
        error = nil

        do {
            let focusStats = try await coreDataSource.calculateFocusStatistics()
            // Merge focus stats into existing statistics
            statistics = SessionStatistics(
                todayMinutes: statistics.todayMinutes,
                thisWeekMinutes: statistics.thisWeekMinutes,
                currentStreak: statistics.currentStreak,
                totalMinutes: statistics.totalMinutes,
                totalSessions: statistics.totalSessions,
                averageSessionDuration: statistics.averageSessionDuration,
                longestSessionDuration: statistics.longestSessionDuration,
                lastSessionDate: statistics.lastSessionDate,
                plannedDuration: statistics.plannedDuration,
                actualDuration: statistics.actualDuration,
                wasPaused: statistics.wasPaused,
                focusTodayMinutes: focusStats.todayMinutes,
                focusThisWeekMinutes: focusStats.thisWeekMinutes,
                focusCurrentStreak: focusStats.currentStreak,
                focusTotalMinutes: focusStats.totalMinutes,
                focusTotalSessions: focusStats.totalSessions,
                focusAverageSessionDuration: focusStats.averageSessionDuration
            )
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Switch data source mode
    func setDataSourceMode(_ mode: DataSourceMode) async {
        // Check if HealthKit available for All Apps mode
        if mode == .allApps {
            await checkHealthKitAvailability()
            guard isHealthKitAvailable else {
                return
            }
        }

        dataSourceMode = mode
        saveDataSourceMode()

        // Reload statistics
        await loadStatistics()
    }

    // MARK: - Private Methods

    /// Get current data source based on mode
    private func currentDataSource() -> MeditationDataSource {
        switch dataSourceMode {
        case .inApp:
            return coreDataSource
        case .allApps:
            return healthKitSource
        }
    }

    /// Save data source mode preference
    private func saveDataSourceMode() {
        UserDefaults.standard.set(dataSourceMode.rawValue, forKey: "StatisticsDataSourceMode")
    }
}
