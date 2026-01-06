//
//  AppLogger.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import OSLog

/// Centralized logging utility for the application
/// Uses OSLog for efficient, privacy-aware logging
enum AppLogger {

    // MARK: - Subsystems

    private static let subsystem = Constants.App.bundleIdentifier

    // MARK: - Categories

    /// Logger for general app lifecycle events
    static let app = Logger(subsystem: subsystem, category: "App")

    /// Logger for meditation timer operations
    static let timer = Logger(subsystem: subsystem, category: "Timer")

    /// Logger for CoreData persistence operations
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")

    /// Logger for CloudKit sync operations
    static let cloudKit = Logger(subsystem: subsystem, category: "CloudKit")

    /// Logger for HealthKit integration
    static let healthKit = Logger(subsystem: subsystem, category: "HealthKit")

    /// Logger for notification operations
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")

    /// Logger for audio playback
    static let audio = Logger(subsystem: subsystem, category: "Audio")

    /// Logger for UI operations
    static let ui = Logger(subsystem: subsystem, category: "UI")

    // MARK: - Convenience Methods

    /// Log an info message
    /// - Parameters:
    ///   - logger: Logger to use
    ///   - message: Message to log
    static func info(_ logger: Logger, _ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    /// Log a debug message
    /// - Parameters:
    ///   - logger: Logger to use
    ///   - message: Message to log
    static func debug(_ logger: Logger, _ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    /// Log an error message
    /// - Parameters:
    ///   - logger: Logger to use
    ///   - message: Error message
    ///   - error: Optional error object
    static func error(_ logger: Logger, _ message: String, error: Error? = nil) {
        if let error = error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .public)")
        }
    }

    /// Log a warning message
    /// - Parameters:
    ///   - logger: Logger to use
    ///   - message: Warning message
    static func warning(_ logger: Logger, _ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    /// Log a fault (critical error)
    /// - Parameters:
    ///   - logger: Logger to use
    ///   - message: Fault message
    ///   - error: Optional error object
    static func fault(_ logger: Logger, _ message: String, error: Error? = nil) {
        if let error = error {
            logger.fault("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.fault("\(message, privacy: .public)")
        }
    }
}

// MARK: - Logger Extension

extension Logger {
    /// Log a message with automatic privacy level
    /// - Parameter message: Message to log
    func log(_ message: String) {
        self.info("\(message, privacy: .public)")
    }
}
