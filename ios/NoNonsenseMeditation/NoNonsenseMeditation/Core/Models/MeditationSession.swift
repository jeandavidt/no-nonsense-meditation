//
//  MeditationSession.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import CoreData

// MARK: - Computed Properties Extension

extension MeditationSession {

    /// Whether the session meets the minimum duration threshold (15 seconds)
    var meetsMinimumDuration: Bool {
        return durationTotal >= 0.25 // 15 seconds = 0.25 minutes
    }

    /// The efficiency ratio of actual meditation time vs total elapsed time
    var efficiencyRatio: Double {
        guard durationElapsed > 0 else { return 0 }
        return durationTotal / durationElapsed
    }

    /// Whether the session was completed as planned without early termination
    var wasCompletedAsPlanned: Bool {
        guard durationPlanned > 0 else { return false }
        let tolerance = 0.1 // 6 seconds
        return abs(durationTotal - Double(durationPlanned)) <= tolerance
    }
}
