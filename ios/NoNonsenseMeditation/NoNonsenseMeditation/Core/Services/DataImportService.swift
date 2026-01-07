//
//  DataImportService.swift
//  NoNonsenseMeditation
//
//  Created by Claude on 2026-01-06.
//

import Foundation
import CoreData

/// Actor-based service for thread-safe session data import operations
actor DataImportService {

    // MARK: - Types

    /// Merge strategy for handling duplicate sessions during import
    enum MergeStrategy {
        /// Skip duplicate sessions, only import new ones
        case skipDuplicates
        /// Replace existing sessions with imported data
        case replaceExisting
        /// Keep both versions by generating new UUIDs for duplicates
        case keepBoth
    }

    /// Result of an import operation
    struct ImportResult {
        /// Number of sessions successfully imported
        let successCount: Int
        /// Number of sessions skipped (duplicates when using skipDuplicates strategy)
        let skippedCount: Int
        /// Number of sessions replaced (when using replaceExisting strategy)
        let replacedCount: Int
        /// Errors encountered during import
        let errors: [ImportError]

        /// Total number of sessions processed
        var totalProcessed: Int {
            successCount + skippedCount + replacedCount
        }

        /// Whether the import was completely successful
        var isSuccess: Bool {
            errors.isEmpty
        }

        /// Human-readable summary of the import operation
        var summary: String {
            var components: [String] = []

            if successCount > 0 {
                components.append("\(successCount) imported")
            }
            if replacedCount > 0 {
                components.append("\(replacedCount) replaced")
            }
            if skippedCount > 0 {
                components.append("\(skippedCount) skipped")
            }
            if !errors.isEmpty {
                components.append("\(errors.count) errors")
            }

            return components.isEmpty ? "No sessions processed" : components.joined(separator: ", ")
        }
    }

    /// Errors that can occur during import operations
    enum ImportError: LocalizedError {
        case invalidFileFormat
        case invalidJSONStructure
        case missingRequiredFields(String)
        case duplicateDetected(count: Int)
        case importFailed(Error)
        case invalidDateFormat(String)
        case invalidUUID(String)
        case coreDataError(String)

        var errorDescription: String? {
            switch self {
            case .invalidFileFormat:
                return "Invalid file format. Expected JSON file."
            case .invalidJSONStructure:
                return "Invalid JSON structure. Expected array of session objects."
            case .missingRequiredFields(let fields):
                return "Missing required fields: \(fields)"
            case .duplicateDetected(let count):
                return "Detected \(count) duplicate session(s)"
            case .importFailed(let error):
                return "Import failed: \(error.localizedDescription)"
            case .invalidDateFormat(let value):
                return "Invalid date format: \(value). Expected ISO8601."
            case .invalidUUID(let value):
                return "Invalid UUID format: \(value)"
            case .coreDataError(let message):
                return "Core Data error: \(message)"
            }
        }
    }

    /// Validated session data ready for import
    struct SessionData {
        let id: UUID
        let plannedDuration: Int16
        let actualDuration: Double
        let elapsedDuration: Double?
        let createdAt: Date
        let completedAt: Date?
        let isValid: Bool
        let wasPaused: Bool
        let pauseCount: Int16
    }

    // MARK: - Properties

    private let persistenceController: PersistenceController
    private let dateFormatter: ISO8601DateFormatter

    // MARK: - Initialization

    /// Initialize the import service
    /// - Parameter persistenceController: The persistence controller to use for Core Data operations
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    // MARK: - Public API

    /// Import sessions from a JSON file
    /// - Parameters:
    ///   - url: URL to the JSON file containing session data
    ///   - strategy: Merge strategy for handling duplicates
    /// - Returns: Import result with counts and any errors encountered
    func importSessions(from url: URL, strategy: MergeStrategy = .skipDuplicates) async -> ImportResult {
        var errors: [ImportError] = []

        // Step 1: Read file data
        guard let data = try? Data(contentsOf: url) else {
            errors.append(.invalidFileFormat)
            return ImportResult(successCount: 0, skippedCount: 0, replacedCount: 0, errors: errors)
        }

        // Step 2: Parse JSON
        let jsonArray: [[String: Any]]
        do {
            jsonArray = try parseJSON(data)
        } catch let error as ImportError {
            errors.append(error)
            return ImportResult(successCount: 0, skippedCount: 0, replacedCount: 0, errors: errors)
        } catch {
            errors.append(.importFailed(error))
            return ImportResult(successCount: 0, skippedCount: 0, replacedCount: 0, errors: errors)
        }

        // Step 3: Validate and convert to SessionData
        let validationResult = validateSessions(jsonArray)
        errors.append(contentsOf: validationResult.errors)

        guard !validationResult.sessions.isEmpty else {
            return ImportResult(successCount: 0, skippedCount: 0, replacedCount: 0, errors: errors)
        }

        // Step 4: Detect duplicates
        let duplicateResult = await detectDuplicates(validationResult.sessions)

        // Step 5: Perform import based on strategy
        let importResult = await performImport(
            newSessions: duplicateResult.new,
            duplicates: duplicateResult.duplicates,
            strategy: strategy
        )

        // Combine all errors
        errors.append(contentsOf: importResult.errors)

        return ImportResult(
            successCount: importResult.successCount,
            skippedCount: importResult.skippedCount,
            replacedCount: importResult.replacedCount,
            errors: errors
        )
    }

    // MARK: - Private Methods

    /// Parse JSON data into array of dictionaries
    /// - Parameter data: Raw JSON data
    /// - Returns: Array of session dictionaries
    /// - Throws: ImportError if JSON is invalid
    private func parseJSON(_ data: Data) throws -> [[String: Any]] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ImportError.invalidJSONStructure
        }

        guard let jsonArray = json as? [[String: Any]] else {
            throw ImportError.invalidJSONStructure
        }

        return jsonArray
    }

    /// Validate sessions and convert to SessionData objects
    /// - Parameter jsonArray: Array of session dictionaries from JSON
    /// - Returns: Tuple of validated sessions and any errors encountered
    private func validateSessions(_ jsonArray: [[String: Any]]) -> (sessions: [SessionData], errors: [ImportError]) {
        var validSessions: [SessionData] = []
        var errors: [ImportError] = []

        for (index, sessionDict) in jsonArray.enumerated() {
            do {
                let sessionData = try validateAndConvertSession(sessionDict, index: index)
                validSessions.append(sessionData)
            } catch let error as ImportError {
                errors.append(error)
            } catch {
                errors.append(.importFailed(error))
            }
        }

        return (validSessions, errors)
    }

    /// Validate a single session dictionary and convert to SessionData
    /// - Parameters:
    ///   - dict: Session dictionary from JSON
    ///   - index: Index in the array for error reporting
    /// - Returns: Validated SessionData object
    /// - Throws: ImportError if validation fails
    private func validateAndConvertSession(_ dict: [String: Any], index: Int) throws -> SessionData {
        var missingFields: [String] = []

        // Validate required field: id
        let id: UUID
        if let idString = dict["id"] as? String,
           let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            if dict["id"] == nil {
                missingFields.append("id")
            } else if let idString = dict["id"] as? String {
                throw ImportError.invalidUUID(idString)
            } else {
                throw ImportError.invalidUUID("(non-string value)")
            }
            id = UUID() // Will be caught by missingFields check
        }

        // Validate required field: plannedDuration
        let plannedDuration: Int16
        if let plannedDurationValue = dict["plannedDuration"] {
            if let value = plannedDurationValue as? Int {
                plannedDuration = Int16(value)
            } else if let value = plannedDurationValue as? Int16 {
                plannedDuration = value
            } else {
                throw ImportError.missingRequiredFields("plannedDuration (invalid type)")
            }
        } else {
            missingFields.append("plannedDuration")
            plannedDuration = 0 // Will be caught by missingFields check
        }

        // Validate required field: actualDuration
        let actualDuration: Double
        if let value = dict["actualDuration"] as? Double {
            actualDuration = value
        } else {
            if dict["actualDuration"] == nil {
                missingFields.append("actualDuration")
            } else {
                throw ImportError.missingRequiredFields("actualDuration (invalid type)")
            }
            actualDuration = 0.0 // Will be caught by missingFields check
        }

        // Validate required field: createdAt
        let createdAt: Date
        if let createdAtString = dict["createdAt"] as? String,
           let date = parseDate(createdAtString) {
            createdAt = date
        } else {
            if dict["createdAt"] == nil {
                missingFields.append("createdAt")
            } else if let dateString = dict["createdAt"] as? String {
                throw ImportError.invalidDateFormat(dateString)
            } else {
                throw ImportError.invalidDateFormat("(non-string value)")
            }
            createdAt = Date() // Will be caught by missingFields check
        }

        // Check if any required fields are missing
        if !missingFields.isEmpty {
            throw ImportError.missingRequiredFields(missingFields.joined(separator: ", "))
        }

        // Parse optional fields
        let elapsedDuration = dict["elapsedDuration"] as? Double

        let completedAt: Date?
        if let completedAtString = dict["completedAt"] as? String {
            completedAt = parseDate(completedAtString)
            if completedAt == nil {
                throw ImportError.invalidDateFormat(completedAtString)
            }
        } else {
            completedAt = nil
        }

        let isValid = dict["isValid"] as? Bool ?? true
        let wasPaused = dict["wasPaused"] as? Bool ?? false

        let pauseCount: Int16
        if let value = dict["pauseCount"] as? Int {
            pauseCount = Int16(value)
        } else if let value = dict["pauseCount"] as? Int16 {
            pauseCount = value
        } else {
            pauseCount = 0
        }

        return SessionData(
            id: id,
            plannedDuration: plannedDuration,
            actualDuration: actualDuration,
            elapsedDuration: elapsedDuration,
            createdAt: createdAt,
            completedAt: completedAt,
            isValid: isValid,
            wasPaused: wasPaused,
            pauseCount: pauseCount
        )
    }

    /// Parse ISO8601 date string
    /// - Parameter dateString: ISO8601 formatted date string
    /// - Returns: Date object or nil if parsing fails
    private func parseDate(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        // Try without fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    /// Detect duplicate sessions by comparing UUIDs with existing sessions
    /// - Parameter sessions: Array of SessionData to check
    /// - Returns: Tuple of new sessions and duplicate sessions
    private func detectDuplicates(_ sessions: [SessionData]) async -> (new: [SessionData], duplicates: [SessionData]) {
        let context = persistenceController.container.viewContext

        // Fetch all existing session IDs
        let fetchRequest = MeditationSession.fetchRequest()
        fetchRequest.propertiesToFetch = ["id"]
        fetchRequest.resultType = .dictionaryResultType

        let existingIDs: Set<UUID>
        do {
            let results = try await context.perform {
                try context.fetch(fetchRequest) as? [[String: Any]] ?? []
            }
            existingIDs = Set(results.compactMap { dict in
                (dict["id"] as? UUID)
            })
        } catch {
            // If we can't fetch existing IDs, treat all as new
            return (new: sessions, duplicates: [])
        }

        // Separate into new and duplicate sessions
        var newSessions: [SessionData] = []
        var duplicates: [SessionData] = []

        for session in sessions {
            if existingIDs.contains(session.id) {
                duplicates.append(session)
            } else {
                newSessions.append(session)
            }
        }

        return (new: newSessions, duplicates: duplicates)
    }

    /// Perform the actual import operation based on the merge strategy
    /// - Parameters:
    ///   - newSessions: Sessions that don't exist in the database
    ///   - duplicates: Sessions that already exist in the database
    ///   - strategy: Merge strategy to apply
    /// - Returns: Import result with counts and errors
    private func performImport(
        newSessions: [SessionData],
        duplicates: [SessionData],
        strategy: MergeStrategy
    ) async -> ImportResult {
        let context = persistenceController.container.newBackgroundContext()
        var successCount = 0
        var skippedCount = 0
        var replacedCount = 0
        var errors: [ImportError] = []

        await context.perform {
            // Always import new sessions
            for sessionData in newSessions {
                do {
                    try self.createSession(from: sessionData, in: context)
                    successCount += 1
                } catch {
                    errors.append(.importFailed(error))
                }
            }

            // Handle duplicates based on strategy
            switch strategy {
            case .skipDuplicates:
                skippedCount = duplicates.count

            case .replaceExisting:
                for sessionData in duplicates {
                    do {
                        try self.replaceSession(with: sessionData, in: context)
                        replacedCount += 1
                    } catch {
                        errors.append(.importFailed(error))
                    }
                }

            case .keepBoth:
                for sessionData in duplicates {
                    do {
                        // Create new session with new UUID
                        var modifiedData = sessionData
                        modifiedData = SessionData(
                            id: UUID(), // Generate new UUID
                            plannedDuration: sessionData.plannedDuration,
                            actualDuration: sessionData.actualDuration,
                            elapsedDuration: sessionData.elapsedDuration,
                            createdAt: sessionData.createdAt,
                            completedAt: sessionData.completedAt,
                            isValid: sessionData.isValid,
                            wasPaused: sessionData.wasPaused,
                            pauseCount: sessionData.pauseCount
                        )
                        try self.createSession(from: modifiedData, in: context)
                        successCount += 1
                    } catch {
                        errors.append(.importFailed(error))
                    }
                }
            }

            // Save context
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    errors.append(.coreDataError("Failed to save context: \(error.localizedDescription)"))
                }
            }
        }

        return ImportResult(
            successCount: successCount,
            skippedCount: skippedCount,
            replacedCount: replacedCount,
            errors: errors
        )
    }

    /// Create a new MeditationSession entity from SessionData
    /// - Parameters:
    ///   - sessionData: Validated session data
    ///   - context: Managed object context to create the entity in
    /// - Throws: Core Data errors
    private func createSession(from sessionData: SessionData, in context: NSManagedObjectContext) throws {
        let session = MeditationSession(context: context)
        session.idSession = sessionData.id
        session.durationPlanned = sessionData.plannedDuration
        session.durationTotal = sessionData.actualDuration
        session.durationElapsed = sessionData.elapsedDuration ?? sessionData.actualDuration
        session.createdAt = sessionData.createdAt
        session.completedAt = sessionData.completedAt
        session.isSessionValid = sessionData.isValid
        session.wasPaused = sessionData.wasPaused
        session.pauseCount = sessionData.pauseCount
        session.syncedToHealthKit = false
        session.syncedToiCloud = false
    }

    /// Replace an existing MeditationSession with new data
    /// - Parameters:
    ///   - sessionData: New session data to replace existing session
    ///   - context: Managed object context containing the session
    /// - Throws: Core Data errors
    private func replaceSession(with sessionData: SessionData, in context: NSManagedObjectContext) throws {
        let fetchRequest = MeditationSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "idSession == %@", sessionData.id as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let existingSession = try context.fetch(fetchRequest).first else {
            throw ImportError.coreDataError("Session with ID \(sessionData.id) not found for replacement")
        }

        // Update all fields
        existingSession.durationPlanned = sessionData.plannedDuration
        existingSession.durationTotal = sessionData.actualDuration
        existingSession.durationElapsed = sessionData.elapsedDuration ?? sessionData.actualDuration
        existingSession.createdAt = sessionData.createdAt
        existingSession.completedAt = sessionData.completedAt
        existingSession.isSessionValid = sessionData.isValid
        existingSession.wasPaused = sessionData.wasPaused
        existingSession.pauseCount = sessionData.pauseCount
    }
}

// MARK: - SessionData Equatable Conformance

extension DataImportService.SessionData: Equatable {
    static func == (lhs: DataImportService.SessionData, rhs: DataImportService.SessionData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - SessionData Hashable Conformance

extension DataImportService.SessionData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
