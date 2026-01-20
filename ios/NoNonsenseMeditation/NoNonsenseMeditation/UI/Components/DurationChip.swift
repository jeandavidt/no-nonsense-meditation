//
//  DurationChip.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-20.
//

import SwiftUI

/// Duration selection chip with glass styling
struct DurationChip: View {

    // MARK: - Properties

    /// Duration in minutes
    let minutes: Int

    /// Whether this chip is selected
    let isSelected: Bool

    /// Action when tapped
    let action: () -> Void

    /// Accent color for selected state
    var accentColor: Color = .accentColor

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    /// Formatted duration label
    private var label: String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    // MARK: - View Body

    var body: some View {
        Button(action: action) {
            Text(label)
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

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            DurationChip(minutes: 5, isSelected: false, action: {})
            DurationChip(minutes: 10, isSelected: true, action: {})
            DurationChip(minutes: 15, isSelected: false, action: {})
        }

        HStack(spacing: 12) {
            DurationChip(minutes: 60, isSelected: false, action: {}, accentColor: .orange)
            DurationChip(minutes: 90, isSelected: true, action: {}, accentColor: .orange)
            DurationChip(minutes: 120, isSelected: false, action: {}, accentColor: .orange)
        }
    }
    .padding()
}
