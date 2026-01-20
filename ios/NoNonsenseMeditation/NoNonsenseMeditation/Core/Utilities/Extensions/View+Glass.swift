//
//  View+Glass.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-19.
//  iOS 26 Liquid Glass Design System Extensions
//

import SwiftUI

// MARK: - Glass Effect Availability Check

/// Environment key for checking if reduce motion is enabled
private struct ReduceMotionEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var reduceMotionEnabled: Bool {
        get { self[ReduceMotionEnvironmentKey.self] }
        set { self[ReduceMotionEnvironmentKey.self] = newValue }
    }
}

// MARK: - Glass Card View Modifier

/// Reusable glass card modifier for container views
@available(iOS 26.0, *)
struct GlassCardModifier: ViewModifier {
    let tint: Color?
    let cornerRadius: CGFloat
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isEnabled && !reduceMotion {
            content
                .glassEffect(
                    tint.map { .regular.tint($0) } ?? .regular,
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            // Fallback for accessibility or disabled state
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
        }
    }
}

/// Fallback glass card modifier for pre-iOS 26
struct GlassCardFallbackModifier: ViewModifier {
    let tint: Color?
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                (tint ?? Color.primary).opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Glass Stat Card Modifier

/// Glass modifier specifically for statistics display cards
@available(iOS 26.0, *)
struct GlassStatCardModifier: ViewModifier {
    let accentColor: Color
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isEnabled && !reduceMotion {
            content
                .glassEffect(
                    .regular.tint(accentColor.opacity(0.3)),
                    in: .rect(cornerRadius: 12)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
        }
    }
}

// MARK: - Glass Button Style

/// Custom glass button style with context-aware tinting
@available(iOS 26.0, *)
struct GlassButtonStyle: ButtonStyle {
    let tint: Color
    let isProminent: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .if(isProminent) { view in
                view.buttonStyle(.glassProminent)
            }
            .if(!isProminent) { view in
                view.buttonStyle(.glass)
            }
            .glassEffect(
                reduceMotion ? .regular.tint(tint) : .regular.tint(tint).interactive(),
                in: .capsule
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(
                reduceMotion ? nil : Constants.Animation.Glass.buttonPress,
                value: configuration.isPressed
            )
    }
}

// MARK: - View Extensions for Glass Effects

extension View {

    // MARK: - Glass Card

    /// Apply glass card styling to a container view
    /// - Parameters:
    ///   - tint: Optional color tint for the glass effect
    ///   - cornerRadius: Corner radius for the card (default: 16)
    ///   - isEnabled: Whether to enable the glass effect (default: true)
    /// - Returns: View with glass card styling
    @ViewBuilder
    func glassCard(
        tint: Color? = nil,
        cornerRadius: CGFloat = Constants.Layout.cardCornerRadius,
        isEnabled: Bool = true
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(GlassCardModifier(
                tint: tint,
                cornerRadius: cornerRadius,
                isEnabled: isEnabled
            ))
        } else {
            self.modifier(GlassCardFallbackModifier(
                tint: tint,
                cornerRadius: cornerRadius
            ))
        }
    }

    // MARK: - Glass Stat Card

    /// Apply glass styling specifically for statistics cards
    /// - Parameters:
    ///   - accentColor: Accent color for the stat card
    ///   - isEnabled: Whether to enable the glass effect (default: true)
    /// - Returns: View with glass stat card styling
    @ViewBuilder
    func glassStatCard(
        accentColor: Color = .accentColor,
        isEnabled: Bool = true
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(GlassStatCardModifier(
                accentColor: accentColor,
                isEnabled: isEnabled
            ))
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
        }
    }

    // MARK: - Glass Capsule

    /// Apply glass capsule styling (ideal for status indicators)
    /// - Parameters:
    ///   - tint: Optional color tint
    ///   - isEnabled: Whether to enable the effect
    /// - Returns: View with glass capsule styling
    @ViewBuilder
    func glassCapsule(
        tint: Color? = nil,
        isEnabled: Bool = true
    ) -> some View {
        if #available(iOS 26.0, *) {
            if isEnabled {
                self.glassEffect(
                    tint.map { .regular.tint($0.opacity(0.6)) } ?? .regular,
                    in: .capsule
                )
            } else {
                self.glassEffect(.identity, in: .capsule)
            }
        } else {
            self
                .background(
                    Capsule()
                        .fill((tint ?? Color.primary).opacity(0.1))
                )
        }
    }

    // MARK: - Interactive Glass

    /// Apply interactive glass effect for touchable elements (iOS 26+ only)
    /// - Parameters:
    ///   - tint: Optional color tint
    ///   - shape: Shape for the glass effect
    /// - Returns: View with interactive glass styling
    @ViewBuilder
    func interactiveGlass<S: Shape>(
        tint: Color? = nil,
        in shape: S
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                tint.map { .regular.tint($0).interactive() } ?? .regular.interactive(),
                in: shape
            )
        } else {
            self
                .background(
                    shape.fill(.ultraThinMaterial)
                )
        }
    }

    // MARK: - Glass Info Container

    /// Apply glass styling for info item containers (Planned, Elapsed displays)
    /// - Parameter tint: Optional tint color
    /// - Returns: View with glass info container styling
    @ViewBuilder
    func glassInfoContainer(tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(8)
                .glassEffect(
                    tint.map { .clear.tint($0.opacity(0.3)) } ?? .clear,
                    in: .rect(cornerRadius: 8)
                )
        } else {
            self
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }

    // MARK: - Glass Section Container

    /// Apply glass styling for section containers (background sounds, duration picker)
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the container
    /// - Returns: View with glass section container styling
    @ViewBuilder
    func glassSectionContainer(cornerRadius: CGFloat = 12) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Glass Effect Container Wrapper

/// Wrapper view for grouping related glass elements with morphing transitions
@available(iOS 26.0, *)
struct GlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = Constants.Animation.Glass.containerSpacing, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

/// Fallback container for pre-iOS 26
struct GlassContainerFallback<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 40.0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        content
    }
}

// MARK: - Conditional Glass Container

/// Container that automatically uses the appropriate glass implementation
struct AdaptiveGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 40.0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassContainer(spacing: spacing) {
                content
            }
        } else {
            GlassContainerFallback(spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - Glass Button Wrapper

/// Convenience view for creating glass-styled buttons
struct GlassButton: View {
    let title: String
    let systemImage: String?
    let tint: Color
    let isProminent: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String,
        systemImage: String? = nil,
        tint: Color = .accentColor,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isProminent = isProminent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .applyGlassButtonStyle(tint: tint, isProminent: isProminent)
    }
}

// MARK: - Button Style Application

extension View {
    /// Apply glass button style with appropriate fallback
    /// - Parameters:
    ///   - tint: Color tint for the button
    ///   - isProminent: Whether this is a primary action button
    /// - Returns: View with glass button styling
    @ViewBuilder
    func applyGlassButtonStyle(tint: Color, isProminent: Bool) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                self
                    .buttonStyle(.glassProminent)
                    .tint(tint)
                    .controlSize(.large)
            } else {
                self
                    .buttonStyle(.glass)
                    .tint(tint)
                    .controlSize(.large)
            }
        } else {
            if isProminent {
                self
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
                    .controlSize(.large)
            } else {
                self
                    .buttonStyle(.bordered)
                    .tint(tint)
                    .controlSize(.large)
            }
        }
    }
}

// MARK: - Glass Filter Button Style

/// Glass-styled filter button for category/type selection
struct GlassFilterButton: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String,
        isSelected: Bool,
        tint: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !reduceMotion {
                withAnimation(Constants.Animation.Glass.morphing) {
                    action()
                }
            } else {
                action()
            }
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .glassFilterButtonBackground(isSelected: isSelected, tint: tint)
    }
}

// MARK: - Glass Filter Button Background Extension

extension View {
    /// Apply glass filter button background styling
    @ViewBuilder
    func glassFilterButtonBackground(isSelected: Bool, tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(
                    isSelected
                        ? .regular.tint(tint).interactive()
                        : .clear.interactive(),
                    in: .capsule
                )
        } else {
            self
                .background(
                    Capsule()
                        .fill(isSelected ? tint : Color.primary.opacity(0.05))
                )
        }
    }
}

// MARK: - Achievement Card Glass Style

extension View {
    /// Apply glass styling for achievement cards
    /// - Parameters:
    ///   - isUnlocked: Whether the achievement is unlocked
    ///   - color: Achievement color
    /// - Returns: View with achievement card glass styling
    @ViewBuilder
    func glassAchievementCard(isUnlocked: Bool, color: Color) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(
                    isUnlocked
                        ? .regular.tint(color.opacity(0.2)).interactive()
                        : .clear,
                    in: .rect(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.02))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
}

// MARK: - Session Summary Card Glass Style

extension View {
    /// Apply glass styling for session summary cards with success/failure tint
    /// - Parameters:
    ///   - isValid: Whether the session was valid (successful)
    ///   - sessionType: Type of session (meditation/focus)
    /// - Returns: View with session summary glass styling
    @ViewBuilder
    func glassSummaryCard(isValid: Bool, sessionType: SessionType) -> some View {
        let tintColor = isValid ? sessionType.color : Color.gray

        if #available(iOS 26.0, *) {
            self
                .padding()
                .glassEffect(
                    .regular.tint(tintColor.opacity(0.15)),
                    in: .rect(cornerRadius: 12)
                )
        } else {
            self
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tintColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
