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
        var newlyUnlocked: [Achievement] = []

        do {
            let sessions = try sessionService.fetchValidSessions()
            let totalMinutes = sessions.reduce(0) { $0 + $1.durationTotal }

            let streakCalculator = StreakCalculator()
            let streak = streakCalculator.calculateCurrentStreak(from: sessions)

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
