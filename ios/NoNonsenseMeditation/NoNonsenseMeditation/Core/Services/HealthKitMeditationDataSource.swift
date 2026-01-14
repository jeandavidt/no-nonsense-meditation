//
//  HealthKitMeditationDataSource.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-08.
//

import Foundation
import HealthKit

/// Data source implementation using HealthKit (all meditation apps)
final class HealthKitMeditationDataSource: MeditationDataSource {

    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService = HealthKitService()) {
        self.healthKitService = healthKitService
    }

    func calculateStatistics() async throws -> SessionStatistics {
        let samples = try await healthKitService.queryMindfulSessions(
            from: Date.distantPast,
            to: Date()
        )

        // Convert to normalized format
        let sessions = samples.map { sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            let session = MeditationSessionData(
                id: UUID(uuidString: sample.uuid.uuidString) ?? UUID(),
                createdAt: sample.startDate,
                completedAt: sample.endDate,
                durationMinutes: duration,
                isValid: duration >= 0.25, // 15 seconds minimum
                source: .healthKit
            )
            #if DEBUG
            print("[HealthKitDS] Sample: duration=\(String(format: "%.2f", duration))min, isValid=\(session.isValid), date=\(sample.startDate)")
            #endif
            return session
        }.filter { $0.isValid }
        
        #if DEBUG
        print("[HealthKitDS] Total HealthKit samples: \(samples.count), Valid sessions: \(sessions.count)")
        #endif

        // Calculate date ranges
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!

        // Filter by date
        let todaySessions = sessions.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }
        let weekSessions = sessions.filter { $0.createdAt >= weekStart }

        // Calculate metrics
        let todayMinutes = todaySessions.reduce(0.0) { $0 + $1.durationMinutes }
        let weekMinutes = weekSessions.reduce(0.0) { $0 + $1.durationMinutes }
        let totalMinutes = sessions.reduce(0.0) { $0 + $1.durationMinutes }
        let totalSessions = sessions.count

        let averageDuration = totalSessions > 0 ? totalMinutes / Double(totalSessions) : 0.0
        let longestDuration = sessions.map { $0.durationMinutes }.max() ?? 0.0

        let currentStreak = calculateCurrentStreakFromSessions(sessions)
        let lastDate = sessions.sorted(by: { $0.createdAt > $1.createdAt }).first?.createdAt
        
        #if DEBUG
        print("[HealthKitDS] Calculated currentStreak: \(currentStreak)")
        #endif
        
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
        let samples = try await healthKitService.queryMindfulSessions(
            from: Date.distantPast,
            to: Date()
        )

        let sessions = samples.compactMap { sample -> MeditationSessionData? in
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            guard duration >= 0.25 else { return nil }

            return MeditationSessionData(
                id: UUID(uuidString: sample.uuid.uuidString) ?? UUID(),
                createdAt: sample.startDate,
                completedAt: sample.endDate,
                durationMinutes: duration,
                isValid: true,
                source: .healthKit
            )
        }

        return calculateCurrentStreakFromSessions(sessions)
    }

    func calculateLongestStreak() async throws -> Int {
        let samples = try await healthKitService.queryMindfulSessions(
            from: Date.distantPast,
            to: Date()
        )

        let sessions = samples.compactMap { sample -> MeditationSessionData? in
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            guard duration >= 0.25 else { return nil }

            return MeditationSessionData(
                id: UUID(uuidString: sample.uuid.uuidString) ?? UUID(),
                createdAt: sample.startDate,
                completedAt: sample.endDate,
                durationMinutes: duration,
                isValid: true,
                source: .healthKit
            )
        }

        return calculateLongestStreakFromSessions(sessions)
    }

    func calculateFocusStatistics() async throws -> SessionStatistics {
        // HealthKit doesn't distinguish between meditation and focus sessions
        // Return empty focus statistics
        return SessionStatistics(
            todayMinutes: 0,
            thisWeekMinutes: 0,
            currentStreak: 0,
            totalMinutes: 0,
            totalSessions: 0,
            averageSessionDuration: 0,
            longestSessionDuration: 0,
            lastSessionDate: nil,
            plannedDuration: 0,
            actualDuration: 0,
            wasPaused: false,
            focusTodayMinutes: 0,
            focusThisWeekMinutes: 0,
            focusCurrentStreak: 0,
            focusTotalMinutes: 0,
            focusTotalSessions: 0,
            focusAverageSessionDuration: 0
        )
    }

    // MARK: - Private Helpers

    /// Calculate streak from normalized session data
    private func calculateCurrentStreakFromSessions(_ sessions: [MeditationSessionData]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group by day
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.createdAt)
        }

        // Check today or yesterday
        let hasMeditatedToday = sessionsByDay.keys.contains { calendar.isDate($0, inSameDayAs: today) }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let hasMeditatedYesterday = sessionsByDay.keys.contains { calendar.isDate($0, inSameDayAs: yesterday) }

        guard hasMeditatedToday || hasMeditatedYesterday else {
            return 0
        }

        // Count backwards
        var streakCount = 0
        var currentDate = hasMeditatedToday ? today : yesterday

        while sessionsByDay.keys.contains(where: { calendar.isDate($0, inSameDayAs: currentDate) }) {
            streakCount += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streakCount
    }

    /// Calculate longest streak from normalized session data
    private func calculateLongestStreakFromSessions(_ sessions: [MeditationSessionData]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.createdAt)
        }

        let sortedDays = sessionsByDay.keys.sorted()

        var longestStreak = 0
        var currentStreak = 1

        for i in 1..<sortedDays.count {
            let previousDay = sortedDays[i - 1]
            let currentDay = sortedDays[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(nextDay, inSameDayAs: currentDay) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return max(longestStreak, currentStreak)
    }
}
