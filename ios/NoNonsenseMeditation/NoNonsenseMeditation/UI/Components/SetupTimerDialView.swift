//
//  SetupTimerDialView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-20.
//

import SwiftUI

/// Preview timer dial for the setup screen
/// Shows selected duration with smooth glow animation and circular swipe gesture support
struct SetupTimerDialView: View {

    // MARK: - Properties

    /// Selected duration in minutes (binding for swipe interaction)
    @Binding var durationMinutes: Int

    /// Session type for color theming
    var sessionType: SessionType = .meditation

    /// Size of the dial
    private let size: CGFloat = 200

    /// Stroke width for the ring
    private let strokeWidth: CGFloat = 8

    /// Subtle glow animation state
    @State private var glowOpacity: Double = 0.08

    /// Drag state for circular gesture
    @State private var isDragging = false
    @State private var dragStartAngleDegrees: Double = 0
    @State private var initialDuration: Int = 0

    /// Available duration options for snapping
    private let durationOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120]
    private let minDuration = 5
    private let maxDuration = 120

    // MARK: - Computed Properties

    /// Formatted duration string
    private var formattedDuration: String {
        if durationMinutes >= 60 {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            if mins == 0 {
                return String(format: "%d:00:00", hours)
            } else {
                return String(format: "%d:%02d:00", hours, mins)
            }
        } else {
            return String(format: "%02d:00", durationMinutes)
        }
    }

    /// Duration label text
    private var durationLabel: String {
        if durationMinutes >= 60 {
            let hours = durationMinutes / 60
            return hours == 1 ? "hour" : "hours"
        } else {
            return durationMinutes == 1 ? "minute" : "minutes"
        }
    }

    /// Theme color based on session type
    private var themeColor: Color {
        sessionType == .meditation ? .green : .orange
    }

    // MARK: - View Body

    var body: some View {
        ZStack {
            // Outer glow (subtle, static)
            Circle()
                .fill(themeColor.opacity(glowOpacity))
                .frame(width: size + 40, height: size + 40)
                .blur(radius: 20)
                .scaleEffect(isDragging ? 1.1 : 1.0)

            // Background ring with glass effect
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)

            // Decorative tick marks
            tickMarks

            // Accent ring segment (decorative, shows ~25% to hint at progress)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [themeColor.opacity(0.3), themeColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(0)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text(formattedDuration)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .scaleEffect(isDragging ? 1.05 : 1.0)

                Text(durationLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    handleDragChanged(location: value.location)
                }
                .onEnded { _ in
                    handleDragEnded()
                }
        )
        .onAppear {
            // Smooth glow pulse (gentle, no bouncing)
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                glowOpacity = 0.12
            }
        }
    }

    // MARK: - Gesture Handlers

    /// Handle drag gesture changes
    private func handleDragChanged(location: CGPoint) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        // Calculate angle in degrees, adjusting so 0 is at top
        var angleDegrees = atan2(dy, dx) * 180 / .pi + 90
        
        // Normalize to 0-360
        while angleDegrees < 0 { angleDegrees += 360 }
        while angleDegrees >= 360 { angleDegrees -= 360 }

        if !isDragging {
            // Start of drag
            isDragging = true
            dragStartAngleDegrees = angleDegrees
            initialDuration = durationMinutes
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }

        // Calculate angle change from start
        var angleDiff = angleDegrees - dragStartAngleDegrees
        
        // Normalize angle difference
        while angleDiff > 180 { angleDiff -= 360 }
        while angleDiff < -180 { angleDiff += 360 }

        // Convert angle to duration change (full circle = 30 minutes)
        let minutesChange = Int(angleDiff / 12) // ~2.5 degrees per minute
        
        var newDuration = initialDuration + minutesChange
        newDuration = max(minDuration, min(maxDuration, newDuration))
        
        // Snap to nearest option if not actively dragging far
        if abs(minutesChange) < 3 {
            newDuration = findNearestDuration(from: newDuration)
        }

        if newDuration != durationMinutes {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.easeOut(duration: 0.1)) {
                durationMinutes = newDuration
            }
        }
    }

    /// Handle drag gesture end
    private func handleDragEnded() {
        isDragging = false
        // Snap to nearest duration option
        let snapped = findNearestDuration(from: durationMinutes)
        if snapped != durationMinutes {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                durationMinutes = snapped
            }
        }
    }

    /// Find the nearest duration from the available options
    private func findNearestDuration(from value: Int) -> Int {
        var nearest = durationOptions[0]
        var minDiff = abs(value - nearest)

        for option in durationOptions {
            let diff = abs(value - option)
            if diff < minDiff {
                minDiff = diff
                nearest = option
            }
        }
        return nearest
    }

    // MARK: - Subviews

    /// Subtle tick marks around the ring
    private var tickMarks: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(Color.gray.opacity(index % 3 == 0 ? 0.4 : 0.2))
                    .frame(width: index % 3 == 0 ? 2 : 1, height: index % 3 == 0 ? 10 : 6)
                    .offset(y: -size / 2 + 20)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        SetupTimerDialView(durationMinutes: .constant(10), sessionType: .meditation)
        SetupTimerDialView(durationMinutes: .constant(30), sessionType: .focus)
    }
    .padding()
}
