//
//  SessionType.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-14.
//

import Foundation
import CoreData
import SwiftUI

/// Enum representing the type of session (meditation or focus)
enum SessionType: String, Codable, CaseIterable, Identifiable {
    case meditation = "meditation"
    case focus = "focus"
    
    var id: String { rawValue }
    
    /// Display name for the session type
    var displayName: String {
        switch self {
        case .meditation:
            return "Meditation"
        case .focus:
            return "Focus"
        }
    }
    
    /// Short description for UI
    var shortDescription: String {
        switch self {
        case .meditation:
            return "Mindfulness"
        case .focus:
            return "Deep Work"
        }
    }
    
    /// SF Symbol name for the session type icon
    var iconName: String {
        switch self {
        case .meditation:
            return "leaf.fill"
        case .focus:
            return "brain.head.profile"
        }
    }
    
    /// SF Symbol name for the session completion
    var completionIconName: String {
        switch self {
        case .meditation:
            return "checkmark.circle.fill"
        case .focus:
            return "bolt.fill"
        }
    }
    
    /// Color name for the session type
    var colorName: String {
        switch self {
        case .meditation:
            return "green"
        case .focus:
            return "orange"
        }
    }

    /// SwiftUI Color for the session type
    var color: Color {
        switch self {
        case .meditation:
            return .green
        case .focus:
            return .orange
        }
    }
}

// MARK: - CoreData Transformable Support

extension SessionType {
    /// Initialize from CoreData raw value
    init?(rawValue: String) {
        switch rawValue {
        case "meditation":
            self = .meditation
        case "focus":
            self = .focus
        default:
            return nil
        }
    }
    
    /// Convert to raw value for CoreData storage
    var toRawValue: String {
        rawValue
    }
}

// MARK: - Default Value

extension SessionType {
    /// Default session type (meditation)
    static var `default`: SessionType {
        .meditation
    }
}
