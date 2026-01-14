//
//  AchievementService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-09.
//

import Foundation
import CoreData
import Observation

@Observable
@MainActor
class AchievementService {
    static let shared = AchievementService()

    private let persistenceController: PersistenceController
    private let sessionService: MeditationSessionService

    private(set) var unlockedAchievements: Set<String> = []

    private init(
        persistenceController: PersistenceController = .shared,
        sessionService: MeditationSessionService = MeditationSessionService()
    ) {
        self.persistenceController = persistenceController
        self.sessionService = sessionService
        loadUnlockedAchievements()
    }

    private func loadUnlockedAchievements() {
        do {
            let sessions = try sessionService.fetchAllSessions()
            unlockedAchievements = Set(sessions.compactMap { session in
                session.achievements as? [String]
            }.flatMap { $0 })
        } catch {
            print("[AchievementService] Failed to load achievements: \(error)")
        }
    }

    func checkAndUnlockAchievements() -> [Achievement] {
        return checkAndUnlockAchievements(for: nil)
    }

    /// Check and unlock achievements for a specific session type
    /// - Parameter sessionType: The session type to check achievements for, or nil for all
    /// - Returns: Array of newly unlocked achievements
    func checkAndUnlockAchievements(for sessionType: SessionType?) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        do {
            let sessions: [MeditationSession]
            let focusSessions: [MeditationSession]

            if let specificType = sessionType {
                sessions = try sessionService.fetchValidSessions(byType: specificType)
                focusSessions = specificType == .focus ? sessions : []
            } else {
                sessions = try sessionService.fetchValidSessions()
                focusSessions = try sessionService.fetchValidSessions(byType: .focus)
            }

            let totalMinutes = sessions.reduce(0) { $0 + $1.durationTotal }
            let focusTotalMinutes = focusSessions.reduce(0) { $0 + $1.durationTotal }

            let streakCalculator = StreakCalculator()
            let streak = streakCalculator.calculateCurrentStreak(from: sessions)
            let focusStreak = streakCalculator.calculateCurrentStreak(from: focusSessions)

            let allAchievements = Achievement.allAchievements

            for achievement in allAchievements {
                if unlockedAchievements.contains(achievement.id) {
                    continue
                }

                let isUnlocked: Bool
                switch achievement.type {
                case .totalSessions:
                    isUnlocked = sessions.count >= achievement.threshold
                case .streak:
                    isUnlocked = streak >= achievement.threshold
                case .totalMinutes:
                    isUnlocked = Int(totalMinutes) >= achievement.threshold
                case .focusTotalSessions:
                    isUnlocked = focusSessions.count >= achievement.threshold
                case .focusStreak:
                    isUnlocked = focusStreak >= achievement.threshold
                case .focusTotalMinutes:
                    isUnlocked = Int(focusTotalMinutes) >= achievement.threshold
                }

                if isUnlocked {
                    unlockedAchievements.insert(achievement.id)
                    newlyUnlocked.append(achievement)
                }
            }
        } catch {
            print("[AchievementService] Failed to check achievements: \(error)")
        }

        return newlyUnlocked
    }

    func getUnlockedAchievements() -> [Achievement] {
        Achievement.allAchievements.filter { unlockedAchievements.contains($0.id) }
    }

    func getLockedAchievements() -> [Achievement] {
        Achievement.allAchievements.filter { !unlockedAchievements.contains($0.id) }
    }

    func saveAchievementsToSession(_ session: MeditationSession, achievements: [Achievement]) throws {
        let achievementIds = achievements.map { $0.id }
        session.achievements = achievementIds as NSObject
        session.isSessionValid = true
        try persistenceController.viewContext.save()
    }

    func getAchievementsForSession(_ session: MeditationSession) -> [Achievement] {
        guard let achievementIds = session.achievements as? [String] else {
            return []
        }
        return Achievement.allAchievements.filter { achievementIds.contains($0.id) }
    }

    func resetAllAchievements() {
        unlockedAchievements.removeAll()
    }
}
