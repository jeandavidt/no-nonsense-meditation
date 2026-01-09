//
//  CoreDataMeditationDataSource.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-08.
//

import Foundation
import CoreData

/// Data source implementation using local CoreData storage
final class CoreDataMeditationDataSource: MeditationDataSource {

    private let sessionService: MeditationSessionService
    private let streakCalculator: StreakCalculator

    init(sessionService: MeditationSessionService = MeditationSessionService()) {
        self.sessionService = sessionService
        self.streakCalculator = StreakCalculator()
    }

    func calculateStatistics() async throws -> SessionStatistics {
        let allSessions = try sessionService.fetchValidSessions()

        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!

        // Filter by date
        let todaySessions = allSessions.filter { session in
            guard let createdAt = session.createdAt else { return false }
            return calendar.isDate(createdAt, inSameDayAs: now)
        }

        let weekSessions = allSessions.filter { session in
            guard let createdAt = session.createdAt else { return false }
            return createdAt >= weekStart
        }

        // Calculate metrics
        let todayMinutes = todaySessions.reduce(0.0) { $0 + $1.durationTotal }
        let weekMinutes = weekSessions.reduce(0.0) { $0 + $1.durationTotal }
        let totalMinutes = allSessions.reduce(0.0) { $0 + $1.durationTotal }
        let totalSessions = allSessions.count

        let averageDuration = totalSessions > 0 ? totalMinutes / Double(totalSessions) : 0.0
        let longestDuration = allSessions.map { $0.durationTotal }.max() ?? 0.0

        let currentStreak = streakCalculator.calculateCurrentStreak(from: allSessions)
        let lastDate = allSessions.first?.createdAt

        return SessionStatistics(
            todayMinutes: todayMinutes,
            thisWeekMinutes: weekMinutes,
            currentStreak: currentStreak,
            totalMinutes: totalMinutes,
            totalSessions: totalSessions,
            averageSessionDuration: averageDuration,
            longestSessionDuration: longestDuration,
            lastSessionDate: lastDate
        )
    }

    func calculateCurrentStreak() async throws -> Int {
        let sessions = try sessionService.fetchValidSessions()
        return streakCalculator.calculateCurrentStreak(from: sessions)
    }

    func calculateLongestStreak() async throws -> Int {
        let sessions = try sessionService.fetchValidSessions()
        return streakCalculator.calculateLongestStreak(from: sessions)
    }
}
