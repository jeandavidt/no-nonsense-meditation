//
//  CircularTimerDial.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// Circular progress indicator for meditation timer
/// Shows remaining time as a circular progress ring
struct CircularTimerDial: View {

    // MARK: - Properties

    /// Current progress (0.0 to 1.0)
    let progress: Double

    /// Total duration in seconds
    let totalDuration: TimeInterval

    /// Remaining time in seconds
    let remainingTime: TimeInterval

    /// Whether the timer is currently running
    let isRunning: Bool

    /// Whether the timer is paused
    let isPaused: Bool

    /// Whether the timer is completed
    let isCompleted: Bool

    // MARK: - Configuration

    /// Stroke width for the progress ring
    private let strokeWidth: CGFloat = 12

    /// Size of the dial
    private let size: CGFloat = 250

    /// Color scheme
    private let activeColor: Color = .accentColor
    private let inactiveColor: Color = .gray.opacity(0.3)
    private let pausedColor: Color = .yellow
    private let completedColor: Color = .green

    // MARK: - Computed Properties

    /// Current color based on timer state
    private var currentColor: Color {
        if isCompleted {
            return completedColor
        } else if isPaused {
            return pausedColor
        } else if isRunning {
            return activeColor
        } else {
            return inactiveColor
        }
    }

    /// Formatted remaining time
    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Progress percentage
    private var progressPercentage: Int {
        return Int(progress * 100)
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 16) {
            // Circular progress indicator
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        inactiveColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        currentColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90)) // Start from top
                    .animation(.linear(duration: 0.5), value: progress)

                // Center content
                VStack(spacing: 8) {
                    // Time display
                    Text(formattedTime)
                        .font(.system(size: 40, weight: .bold))
                        .contentTransition(.numericText())
                        .foregroundColor(currentColor)
                        .monospacedDigit()

                    // Status indicator
                    statusIndicator
                }
            }

            // Progress text
            if !isCompleted {
                Text("" + String(progressPercentage) + "% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Meditation Complete!")
                    .font(.subheadline)
                    .foregroundColor(completedColor)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Subviews

    /// Status indicator showing timer state
    private var statusIndicator: some View {
        Group {
            if isRunning {
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(currentColor)
                    Text("Running")
                        .font(.caption)
                        .foregroundColor(currentColor)
                }
            } else if isPaused {
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(pausedColor)
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(pausedColor)
                }
            } else if isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(completedColor)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(completedColor)
                }
            } else {
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(currentColor.opacity(0.1))
        .cornerRadius(20)
    }

    // MARK: - Animation

    /// Custom animation for progress changes
    private func progressAnimation() -> Animation {
        return .linear(duration: 0.5)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CircularTimerDial(
            progress: 0.75,
            totalDuration: 600,
            remainingTime: 150,
            isRunning: true,
            isPaused: false,
            isCompleted: false
        )

        CircularTimerDial(
            progress: 1.0,
            totalDuration: 600,
            remainingTime: 0,
            isRunning: false,
            isPaused: false,
            isCompleted: true
        )
    }
    .padding()
}