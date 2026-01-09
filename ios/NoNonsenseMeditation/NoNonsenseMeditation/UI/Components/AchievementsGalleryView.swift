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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            header

            typeFilter

            achievementsGrid
        }
        .padding(Constants.Layout.cardPadding)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(.yellow)

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
                TypeFilterButton(
                    type: nil,
                    title: "All",
                    isSelected: selectedType == nil,
                    action: { selectedType = nil }
                )

                ForEach(AchievementType.allCases) { type in
                    TypeFilterButton(
                        type: type,
                        title: type.displayName,
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }
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

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? Color(white: 0.15)
                    : Color(white: 0.98),
                colorScheme == .dark
                    ? Color(white: 0.12)
                    : Color(white: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct TypeFilterButton: View {
    let type: AchievementType?
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Constants.Colors.accent(for: .light) : Color.primary.opacity(0.05))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .animation(Constants.Animation.buttonSpring, value: isSelected)
        }
        .buttonStyle(.plain)
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
                        .fill(isUnlocked ? achievement.color.opacity(0.15) : Color.primary.opacity(0.03))
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUnlocked ? achievement.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
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
                        .fill(achievement.color.opacity(0.15))
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
                                .fill(achievement.color.opacity(0.15))
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
        }
    }

    var unit: String {
        switch self {
        case .totalSessions: return "sessions"
        case .streak: return "days"
        case .totalMinutes: return "minutes"
        }
    }
}

#Preview {
    AchievementsGalleryView()
}
