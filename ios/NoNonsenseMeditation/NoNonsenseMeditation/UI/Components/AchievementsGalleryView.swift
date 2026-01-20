//
//  AchievementsGalleryView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-09.
//

import SwiftUI

struct AchievementsGalleryView: View {
    @State private var achievementService = AchievementService.shared
    @State private var selectedType: AchievementType?
    @State private var selectedAchievement: Achievement?

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            header

            typeFilter

            achievementsGrid
        }
        .padding(Constants.Layout.cardPadding)
        .glassCard(tint: Color.accentColor.opacity(0.08), cornerRadius: Constants.Layout.cardCornerRadius)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(.accentColor)

            Text("Achievements")
                .font(Constants.Typography.sectionHeader)
                .fontWeight(.bold)

            Spacer()

            HStack(spacing: 4) {
                Text("\(achievementService.getUnlockedAchievements().count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .monospacedDigit()

                Text("of \(Achievement.allAchievements.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            )
        }
    }

    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Spacing.small) {
                FilterPillButton(
                    title: "All",
                    isSelected: selectedType == nil,
                    action: {
                        withAnimation(Constants.Animation.Glass.filterMorph) { selectedType = nil }
                    }
                )

                ForEach(AchievementType.allCases) { type in
                    FilterPillButton(
                        title: type.displayName,
                        isSelected: selectedType == type,
                        accentColor: getTypeColor(type),
                        action: {
                            withAnimation(Constants.Animation.Glass.filterMorph) { selectedType = type }
                        }
                    )
                }
            }
        }
    }

    /// Get a softer accent color for each achievement type
    private func getTypeColor(_ type: AchievementType) -> Color {
        switch type {
        case .totalSessions: return Color(hex: "7FA584") // sage green
        case .streak: return Color(hex: "F4A596") // coral
        case .totalMinutes: return Color(hex: "B8A9C9") // lavender
        case .focusTotalSessions: return Color(hex: "E8A87C") // warm orange
        case .focusStreak: return Color(hex: "F7DC6F") // soft gold
        case .focusTotalMinutes: return Color(hex: "5DADE2") // teal blue
        }
    }

    @ViewBuilder
    private var achievementsGrid: some View {
        let filteredAchievements = filteredAchievementsList

        if filteredAchievements.isEmpty {
            emptyState
        } else {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 110), spacing: Constants.Spacing.small)
            ], spacing: Constants.Spacing.small) {
                ForEach(filteredAchievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: achievementService.unlockedAchievements.contains(achievement.id),
                        action: { selectedAchievement = achievement }
                    )
                }
            }
        }
    }

    private var filteredAchievementsList: [Achievement] {
        let all = Achievement.allAchievements
        guard let type = selectedType else { return all }
        return all.filter { $0.type == type }
    }

    private var emptyState: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No achievements yet")
                .font(Constants.Typography.sectionHeader)
                .foregroundColor(.secondary)

            Text("Keep meditating to unlock achievements!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Spacing.extraLarge)
    }

}

// MARK: - Filter Pill Button

/// A pill-shaped filter button with liquid glass styling
struct FilterPillButton: View {
    let title: String
    let isSelected: Bool
    var accentColor: Color = .accentColor
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(isSelected ? .semibold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .background(
            Group {
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        )
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct TypeFilterButton: View {
    let type: AchievementType?
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .applyGlassFilterButtonStyle(isSelected: isSelected)
        .animation(reduceMotion ? nil : Constants.Animation.buttonSpring, value: isSelected)
    }
}

// MARK: - Glass Filter Button Style Extension

extension View {
    /// Apply glass filter button styling
    @ViewBuilder
    func applyGlassFilterButtonStyle(isSelected: Bool) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(
                    isSelected
                        ? .regular.tint(Constants.Colors.accent(for: .light)).interactive()
                        : .clear.interactive(),
                    in: .capsule
                )
        } else {
            self
                .background(
                    Capsule()
                        .fill(isSelected ? Constants.Colors.accent(for: .light) : Color.primary.opacity(0.05))
                )
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Constants.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.color.opacity(0.12) : Color.primary.opacity(0.03))
                        .frame(width: 60, height: 60)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(isUnlocked ? achievement.color : .secondary.opacity(0.4))
                }

                VStack(spacing: 4) {
                    Text(achievement.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        if isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Constants.Spacing.small)
            .glassAchievementCard(isUnlocked: isUnlocked, color: achievement.color)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.Spacing.large) {
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 48))
                        .foregroundColor(achievement.color)
                }
                .padding(.top, Constants.Spacing.extraLarge)

                VStack(spacing: Constants.Spacing.small) {
                    Text(achievement.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(achievement.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(achievement.color.opacity(0.12))
                        )
                }

                VStack(spacing: Constants.Spacing.small) {
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.large)

                    HStack(spacing: Constants.Spacing.tiny) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text("\(achievement.threshold) \(achievement.type.unit)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.05))
                    )
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension AchievementType {
    var displayName: String {
        switch self {
        case .totalSessions: return "Sessions"
        case .streak: return "Streak"
        case .totalMinutes: return "Minutes"
        case .focusTotalSessions: return "Focus"
        case .focusStreak: return "Focus Streak"
        case .focusTotalMinutes: return "Focus Mins"
        }
    }

    var unit: String {
        switch self {
        case .totalSessions: return "sessions"
        case .streak: return "days"
        case .totalMinutes: return "minutes"
        case .focusTotalSessions: return "sessions"
        case .focusStreak: return "days"
        case .focusTotalMinutes: return "minutes"
        }
    }
}

#Preview {
    AchievementsGalleryView()
}
