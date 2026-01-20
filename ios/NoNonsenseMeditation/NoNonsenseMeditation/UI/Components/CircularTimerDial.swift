//
//  CircularTimerDial.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Polished on 2026-01-20 - Added gradients, glow, tick marks, and smoother animations
//

import SwiftUI

/// Circular progress indicator for meditation timer
/// Shows remaining time as a circular progress ring with polish effects
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

    /// Session type for color theming
    var sessionType: SessionType = .meditation

    // MARK: - Configuration

    /// Stroke width for the progress ring
    private let strokeWidth: CGFloat = 12

    /// Size of the dial
    private let size: CGFloat = 250

    /// Color scheme
    private var activeColor: Color {
        sessionType == .meditation ? .green : .orange
    }
    private let inactiveColor: Color = .gray.opacity(0.2)
    private let pausedColor: Color = .yellow
    private let completedColor: Color = .green

    // MARK: - State

    /// Glow animation state
    @State private var glowIntensity: Double = 0.3

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

    /// Gradient for the progress ring
    private var progressGradient: AngularGradient {
        let baseColor = currentColor
        return AngularGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.5),
                baseColor.opacity(0.7),
                baseColor
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress)
        )
    }

    /// Formatted remaining time
    private var formattedTime: String {
        let absTime = abs(remainingTime)
        let minutes = Int(absTime) / 60
        let seconds = Int(absTime) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)

        if remainingTime < 0 {
            return "+\(timeString)"
        } else {
            return timeString
        }
    }

    /// Progress percentage
    private var progressPercentage: Int {
        return Int(progress * 100)
    }

    /// Whether in overtime
    private var isOvertime: Bool {
        remainingTime < 0
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 16) {
            // Circular progress indicator
            ZStack {
                // Outer glow when running
                if isRunning {
                    Circle()
                        .fill(currentColor.opacity(0.15))
                        .frame(width: size, height: size)
                        .blur(radius: 20)
                        .allowsHitTesting(false)
                }

                // Tick marks
                tickMarks

                // Background ring
                Circle()
                    .stroke(
                        inactiveColor,
                        style: StrokeStyle(lineWidth: strokeWidth - 4, lineCap: .round)
                    )
                    .frame(width: size, height: size)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                // Progress end cap glow
                if progress > 0 && !isCompleted {
                    let radius = size / 2 
                    let angle = progress * 2 * .pi
                    let x = radius * sin(angle)
                    let y = -radius * cos(angle)
                    
                    // Glow circle behind end cap
                    Circle()
                        .fill(currentColor.opacity(0.4))
                        .frame(width: strokeWidth + 16, height: strokeWidth + 16)
                        .blur(radius: 6)
                        .offset(x: x, y: y)
                    
                    // End cap
                    Circle()
                        .fill(currentColor)
                        .frame(width: strokeWidth + 4, height: strokeWidth + 4)
                        .shadow(color: currentColor.opacity(0.8), radius: 6, x: 0, y: 0)
                        .offset(x: x, y: y)
                }

                // Center content
                VStack(spacing: 8) {
                    // Time display
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .contentTransition(.numericText())
                        .foregroundColor(isOvertime ? .orange : .primary)
                        .monospacedDigit()

                    // Status indicator
                    statusIndicator
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)

            // Progress text
            progressLabel
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isRunning) { _, newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }

    // MARK: - Subviews

    /// Subtle tick marks around the ring
    private var tickMarks: some View {
        ZStack {
            ForEach(0..<60, id: \.self) { index in
                if index % 5 == 0 {
                    // Major tick (every 5 minutes)
                    Rectangle()
                        .fill(Color.gray.opacity(index % 15 == 0 ? 0.5 : 0.3))
                        .frame(width: index % 15 == 0 ? 2 : 1.5, height: index % 15 == 0 ? 12 : 8)
                        .offset(y: -size / 2 + 24)
                        .rotationEffect(.degrees(Double(index) * 6))
                }
            }
        }
    }

    /// Status indicator showing timer state with glass capsule
    private var statusIndicator: some View {
        Group {
            if isRunning {
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 8, height: 8)
                    Text("Running")
                        .font(.caption.weight(.medium))
                        .foregroundColor(currentColor)
                }
            } else if isPaused {
                HStack(spacing: 6) {
                    Image(systemName: "pause.fill")
                        .font(.caption2)
                        .foregroundColor(pausedColor)
                    Text("Paused")
                        .font(.caption.weight(.medium))
                        .foregroundColor(pausedColor)
                }
            } else if isCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(completedColor)
                    Text("Complete")
                        .font(.caption.weight(.medium))
                        .foregroundColor(completedColor)
                }
            } else {
                Text("Ready")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(currentColor.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(currentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    /// Progress label below dial
    private var progressLabel: some View {
        Group {
            if isCompleted {
                Text(sessionType == .meditation ? "Meditation Complete!" : "Focus Session Complete!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(completedColor)
            } else if isOvertime {
                Text("Overtime")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.orange)
            } else {
                Text("\(progressPercentage)% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Animations

    /// Start ambient animations
    private func startAnimations() {
        // No animations - removed bouncing effects
    }

    /// Stop ambient animations
    private func stopAnimations() {
        // No animations to stop
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        CircularTimerDial(
            progress: 0.65,
            totalDuration: 600,
            remainingTime: 210,
            isRunning: true,
            isPaused: false,
            isCompleted: false,
            sessionType: .meditation
        )

        CircularTimerDial(
            progress: 1.0,
            totalDuration: 600,
            remainingTime: -120,
            isRunning: true,
            isPaused: false,
            isCompleted: false,
            sessionType: .focus
        )
    }
    .padding()
}
