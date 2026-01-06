//
//  View+Extensions.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

extension View {

    // MARK: - Card Styling

    /// Apply card-style background and shadow
    /// - Parameters:
    ///   - backgroundColor: Background color (default: system background)
    ///   - cornerRadius: Corner radius (default: from Constants)
    ///   - shadowRadius: Shadow blur radius (default: 8)
    /// - Returns: View with card styling applied
    func cardStyle(
        backgroundColor: Color = Color(.systemBackground),
        cornerRadius: CGFloat = Constants.Layout.cardCornerRadius,
        shadowRadius: CGFloat = 8
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
    }

    // MARK: - Conditional Modifiers

    /// Conditionally apply a modifier
    /// - Parameters:
    ///   - condition: Whether to apply the modifier
    ///   - transform: The modifier to apply
    /// - Returns: View with modifier applied if condition is true
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally apply one of two modifiers
    /// - Parameters:
    ///   - condition: Which modifier to apply
    ///   - ifTransform: Modifier to apply if condition is true
    ///   - elseTransform: Modifier to apply if condition is false
    /// - Returns: View with appropriate modifier applied
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    // MARK: - Haptic Feedback

    /// Add haptic feedback to tap gesture
    /// - Parameter style: Feedback style (default: .light)
    /// - Returns: View with haptic feedback
    func withHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        )
    }

    // MARK: - Accessibility

    /// Hide view from accessibility
    /// - Returns: View hidden from VoiceOver
    func accessibilityHidden() -> some View {
        self.accessibilityHidden(true)
    }

    // MARK: - Navigation

    /// Navigate to a destination view when a binding changes
    /// - Parameters:
    ///   - isActive: Binding to control navigation
    ///   - destination: Destination view
    /// - Returns: View with navigation applied
    @ViewBuilder
    func navigate<Destination: View>(
        when isActive: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        self.background(
            NavigationLink(
                destination: destination(),
                isActive: isActive,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    // MARK: - Loading States

    /// Overlay a loading indicator when loading
    /// - Parameter isLoading: Whether to show loading indicator
    /// - Returns: View with loading overlay
    @ViewBuilder
    func loading(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
            }
        }
    }

    // MARK: - Keyboard

    /// Add toolbar with done button to dismiss keyboard
    /// - Returns: View with keyboard toolbar
    func keyboardDismissToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }

}
