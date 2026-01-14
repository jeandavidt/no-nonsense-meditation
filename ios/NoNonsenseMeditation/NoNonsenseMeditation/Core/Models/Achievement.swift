//
//  Achievement.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-09.
//

import Foundation
import SwiftUI

enum AchievementType: String, Codable, CaseIterable, Identifiable {
    case totalSessions
    case streak
    case totalMinutes
    case focusTotalSessions
    case focusStreak
    case focusTotalMinutes

    var id: String { rawValue }
}

struct Achievement: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let type: AchievementType
    let name: String
    let description: String
    let iconName: String
    let iconColor: String
    let threshold: Int

    init(
        id: String,
        type: AchievementType,
        name: String,
        description: String,
        iconName: String,
        iconColor: String,
        threshold: Int
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.iconName = iconName
        self.iconColor = iconColor
        self.threshold = threshold
    }

    var color: Color {
        switch iconColor {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "pink": return .pink
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .gray
        }
    }
}

extension Achievement {
    static let allAchievements: [Achievement] = [
        totalSessionsAchievements,
        streakAchievements,
        minutesAchievements,
        focusSessionsAchievements,
        focusStreakAchievements,
        focusMinutesAchievements
    ].flatMap { $0 }

    static let totalSessionsAchievements: [Achievement] = [
        Achievement(
            id: "first_session",
            type: .totalSessions,
            name: "First Steps",
            description: "Complete your first meditation session",
            iconName: "leaf.fill",
            iconColor: "green",
            threshold: 1
        ),
        Achievement(
            id: "five_sessions",
            type: .totalSessions,
            name: "Getting Started",
            description: "Complete 5 meditation sessions",
            iconName: "flame.fill",
            iconColor: "orange",
            threshold: 5
        ),
        Achievement(
            id: "ten_sessions",
            type: .totalSessions,
            name: "Rising Star",
            description: "Complete 10 meditation sessions",
            iconName: "star.fill",
            iconColor: "yellow",
            threshold: 10
        ),
        Achievement(
            id: "twenty_five_sessions",
            type: .totalSessions,
            name: "Dedicated Practitioner",
            description: "Complete 25 meditation sessions",
            iconName: "moon.stars.fill",
            iconColor: "indigo",
            threshold: 25
        ),
        Achievement(
            id: "fifty_sessions",
            type: .totalSessions,
            name: "Mindfulness Master",
            description: "Complete 50 meditation sessions",
            iconName: "crown.fill",
            iconColor: "purple",
            threshold: 50
        ),
        Achievement(
            id: "hundred_sessions",
            type: .totalSessions,
            name: "Zen Master",
            description: "Complete 100 meditation sessions",
            iconName: "sparkles",
            iconColor: "cyan",
            threshold: 100
        )
    ]

    static let streakAchievements: [Achievement] = [
        Achievement(
            id: "three_day_streak",
            type: .streak,
            name: "On a Roll",
            description: "Maintain a 3-day meditation streak",
            iconName: "wave.3.left.circle.fill",
            iconColor: "blue",
            threshold: 3
        ),
        Achievement(
            id: "seven_day_streak",
            type: .streak,
            name: "Week Warrior",
            description: "Maintain a 7-day meditation streak",
            iconName: "calendar.badge.clock",
            iconColor: "teal",
            threshold: 7
        ),
        Achievement(
            id: "fourteen_day_streak",
            type: .streak,
            name: "Two Week Triumph",
            description: "Maintain a 14-day meditation streak",
            iconName: "figure.mind.and.body",
            iconColor: "purple",
            threshold: 14
        ),
        Achievement(
            id: "thirty_day_streak",
            type: .streak,
            name: "Month Master",
            description: "Maintain a 30-day meditation streak",
            iconName: "sun.max.fill",
            iconColor: "yellow",
            threshold: 30
        ),
        Achievement(
            id: "sixty_day_streak",
            type: .streak,
            name: "Dedicated Soul",
            description: "Maintain a 60-day meditation streak",
            iconName: "heart.fill",
            iconColor: "red",
            threshold: 60
        ),
        Achievement(
            id: "ninety_day_streak",
            type: .streak,
            name: "Unstoppable",
            description: "Maintain a 90-day meditation streak",
            iconName: "infinity",
            iconColor: "pink",
            threshold: 90
        )
    ]

    static let minutesAchievements: [Achievement] = [
        Achievement(
            id: "fifteen_minutes",
            type: .totalMinutes,
            name: "Quick Start",
            description: "Meditate for 15 total minutes",
            iconName: "timer",
            iconColor: "green",
            threshold: 15
        ),
        Achievement(
            id: "one_hour",
            type: .totalMinutes,
            name: "Hour Power",
            description: "Meditate for 60 total minutes",
            iconName: "clock.fill",
            iconColor: "blue",
            threshold: 60
        ),
        Achievement(
            id: "two_hours",
            type: .totalMinutes,
            name: "Double Time",
            description: "Meditate for 120 total minutes",
            iconName: "hourglass",
            iconColor: "purple",
            threshold: 120
        ),
        Achievement(
            id: "five_hours",
            type: .totalMinutes,
            name: "Marathon Runner",
            description: "Meditate for 300 total minutes",
            iconName: "figure.run",
            iconColor: "orange",
            threshold: 300
        ),
        Achievement(
            id: "ten_hours",
            type: .totalMinutes,
            name: "Endurance King",
            description: "Meditate for 600 total minutes",
            iconName: "mountain.2.fill",
            iconColor: "indigo",
            threshold: 600
        ),
        Achievement(
            id: "twenty_four_hours",
            type: .totalMinutes,
            name: "Day of Zen",
            description: "Meditate for 1440 total minutes (24 hours)",
            iconName: "sun.max.circle.fill",
            iconColor: "yellow",
            threshold: 1440
        )
    ]

    // MARK: - Focus Session Achievements

    static let focusSessionsAchievements: [Achievement] = [
        Achievement(
            id: "first_focus_session",
            type: .focusTotalSessions,
            name: "First Focus",
            description: "Complete your first focus session",
            iconName: "brain.head.profile",
            iconColor: "orange",
            threshold: 1
        ),
        Achievement(
            id: "five_focus_sessions",
            type: .focusTotalSessions,
            name: "Focused Flow",
            description: "Complete 5 focus sessions",
            iconName: "bolt.fill",
            iconColor: "yellow",
            threshold: 5
        ),
        Achievement(
            id: "ten_focus_sessions",
            type: .focusTotalSessions,
            name: "Deep Work",
            description: "Complete 10 focus sessions",
            iconName: "sparkle.magnifyingglass",
            iconColor: "purple",
            threshold: 10
        ),
        Achievement(
            id: "twenty_five_focus_sessions",
            type: .focusTotalSessions,
            name: "Concentration Master",
            description: "Complete 25 focus sessions",
            iconName: "scope",
            iconColor: "teal",
            threshold: 25
        ),
        Achievement(
            id: "fifty_focus_sessions",
            type: .focusTotalSessions,
            name: "Productivity Pro",
            description: "Complete 50 focus sessions",
            iconName: "chart.line.uptrend.xyaxis",
            iconColor: "green",
            threshold: 50
        ),
        Achievement(
            id: "hundred_focus_sessions",
            type: .focusTotalSessions,
            name: "Focus Champion",
            description: "Complete 100 focus sessions",
            iconName: "trophy.fill",
            iconColor: "gold",
            threshold: 100
        )
    ]

    static let focusStreakAchievements: [Achievement] = [
        Achievement(
            id: "three_day_focus_streak",
            type: .focusStreak,
            name: "Focus Starter",
            description: "Maintain a 3-day focus streak",
            iconName: "brain",
            iconColor: "orange",
            threshold: 3
        ),
        Achievement(
            id: "seven_day_focus_streak",
            type: .focusStreak,
            name: "Weekly Warrior",
            description: "Maintain a 7-day focus streak",
            iconName: "calendar.badge.checkmark",
            iconColor: "yellow",
            threshold: 7
        ),
        Achievement(
            id: "fourteen_day_focus_streak",
            type: .focusStreak,
            name: "Two Week Focus",
            description: "Maintain a 14-day focus streak",
            iconName: "target",
            iconColor: "red",
            threshold: 14
        ),
        Achievement(
            id: "thirty_day_focus_streak",
            type: .focusStreak,
            name: "Focus Month",
            description: "Maintain a 30-day focus streak",
            iconName: "calendar",
            iconColor: "purple",
            threshold: 30
        )
    ]

    static let focusMinutesAchievements: [Achievement] = [
        Achievement(
            id: "one_hour_focus",
            type: .focusTotalMinutes,
            name: "One Hour Deep Work",
            description: "Focus for 60 total minutes",
            iconName: "timer",
            iconColor: "orange",
            threshold: 60
        ),
        Achievement(
            id: "three_hours_focus",
            type: .focusTotalMinutes,
            name: "Three Hour Focus",
            description: "Focus for 180 total minutes",
            iconName: "clock.fill",
            iconColor: "yellow",
            threshold: 180
        ),
        Achievement(
            id: "five_hours_focus",
            type: .focusTotalMinutes,
            name: "Five Hours Flow",
            description: "Focus for 300 total minutes",
            iconName: "hourglass",
            iconColor: "purple",
            threshold: 300
        ),
        Achievement(
            id: "ten_hours_focus",
            type: .focusTotalMinutes,
            name: "Ten Hours Mastery",
            description: "Focus for 600 total minutes",
            iconName: "mountain.2.fill",
            iconColor: "teal",
            threshold: 600
        ),
        Achievement(
            id: "twenty_five_hours_focus",
            type: .focusTotalMinutes,
            name: "Quarter Century Focus",
            description: "Focus for 1500 total minutes",
            iconName: "star.fill",
            iconColor: "gold",
            threshold: 1500
        )
    ]
}
