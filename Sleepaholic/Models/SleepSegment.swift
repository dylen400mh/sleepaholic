//
//  SleepSegment.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-15.
//

import Foundation

/// High-level sleep stages we care about for insights + visualization.
enum SleepStage: String, Codable, CaseIterable {
    /// User is in bed but not necessarily asleep (HealthKit: .inBed)
    case inBed
    
    /// Generic "asleep" when no finer staging is available
    case asleepUnspecified
    
    /// Light / core sleep (HealthKit: .asleepCore)
    case core
    
    /// Deep sleep (HealthKit: .asleepDeep)
    case deep
    
    /// REM sleep (HealthKit: .asleepREM)
    case rem
    
    /// Awake while in a sleep session (HealthKit: .awake)
    case awake
}

/// Represents a continuous segment of a sleep session, such as
/// "in bed", "asleep (core)", "asleep (deep)", "awake", etc.
struct SleepSegment: Identifiable, Codable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let stage: SleepStage
    
    init(id: UUID = UUID(), start: Date, end: Date, stage: SleepStage) {
        self.id = id
        self.start = start
        self.end = end
        self.stage = stage
    }
    
    /// Convenience: duration of this segment in seconds
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

