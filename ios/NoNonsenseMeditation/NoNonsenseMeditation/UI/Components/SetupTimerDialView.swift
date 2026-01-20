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
    private let size: CGFloat = 250

    /// Stroke width for the ring
    private let strokeWidth: CGFloat = 8

    /// Subtle glow animation state
    @State private var glowOpacity: Double = 0.08

    /// Drag state for circular gesture
    @State private var isDragging = false
    
    /// Cumulative angle for tracking multiple rotations
    @State private var cumulativeAngleDegrees: Double = 0
    @State private var dragStartAngleDegrees: Double = 0

    /// Available duration options
    private let durationOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120]
    private let minDuration = 1
    private let maxDuration = 720

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

    /// Progress for the arc (0-1, based on duration)
    private var progress: Double {
        Double(durationMinutes) / Double(maxDuration)
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

            // Minute tick marks (every 6 degrees = 1 minute)
            tickMarks

            // Progress arc showing selected duration
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    themeColor,
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
            // Initialize cumulative angle based on current duration
            // duration = (angle / 6) + 1, so angle = (duration - 1) * 6
            cumulativeAngleDegrees = Double(durationMinutes - 1) * 6.0
            
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
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }

        // Calculate angle change from start
        var angleDiff = angleDegrees - dragStartAngleDegrees
        
        // Normalize angle difference to -180 to 180
        while angleDiff > 180 { angleDiff -= 360 }
        while angleDiff < -180 { angleDiff += 360 }
        
        // Update cumulative angle
        cumulativeAngleDegrees += angleDiff
        dragStartAngleDegrees = angleDegrees
        
        // Clamp cumulative angle to valid range
        // Min: 0° (1 minute), Max: 4319° (720 minutes)
        let minAngle = 0.0
        let maxAngle = Double(maxDuration - 1) * 6.0
        cumulativeAngleDegrees = max(minAngle, min(maxAngle, cumulativeAngleDegrees))
        
        // Calculate duration from cumulative angle: 6° = 1 minute
        // duration = (angle / 6) + 1
        let newDuration = Int(cumulativeAngleDegrees / 6.0) + 1
        
        if newDuration != durationMinutes {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            durationMinutes = newDuration
        }
    }

    /// Handle drag gesture end
    private func handleDragEnded() {
        isDragging = false
    }

    // MARK: - Subviews

    /// Tick marks around the ring (every 6 degrees = 1 minute)
    private var tickMarks: some View {
        ZStack {
            // Minor ticks every 6 degrees (60 ticks per rotation)
            ForEach(0..<60, id: \.self) { index in
                Rectangle()
                    .fill(Color.gray.opacity(index % 6 == 0 ? 0.5 : 0.2))
                    .frame(
                        width: index % 6 == 0 ? 1.5 : 1,
                        height: index % 6 == 0 ? 10 : 6
                    )
                    .offset(y: -size / 2 + 20)
                    .rotationEffect(.degrees(Double(index) * 6))
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
