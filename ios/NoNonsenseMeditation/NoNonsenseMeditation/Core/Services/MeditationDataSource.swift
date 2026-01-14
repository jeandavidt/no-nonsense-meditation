//
//  MeditationDataSource.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-08.
//

import Foundation

/// Protocol for providing meditation session data from various sources
protocol MeditationDataSource: Sendable {
    /// Calculate statistics from available data
    func calculateStatistics() async throws -> SessionStatistics

    /// Calculate focus-specific statistics
    func calculateFocusStatistics() async throws -> SessionStatistics

    /// Calculate current streak
    func calculateCurrentStreak() async throws -> Int

    /// Calculate longest streak
    func calculateLongestStreak() async throws -> Int
}

/// Normalized session data structure for cross-source compatibility
struct MeditationSessionData: Sendable, Equatable {
    let id: UUID
    let createdAt: Date
    let completedAt: Date?
    let durationMinutes: Double
    let isValid: Bool
    let source: DataSource

    enum DataSource: String, Sendable {
        case inApp = "No Nonsense Meditation"
        case healthKit = "HealthKit (All Apps)"
    }
}
