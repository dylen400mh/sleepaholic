//
//  SleepSegment.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-15.
//

import Foundation
import SwiftUI

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

extension SleepStage {
    var color: Color {
        switch self {
        case .inBed:
            return Color.white20
        case .asleepUnspecified:
            return Color.red
        case .core:
            return Color.blue
        case .deep:
            return Color.purple
        case .rem:
            return Color.green
        case .awake:
            return Color.yellow
        }
    }

    var name: String {
        switch self {
        case .inBed:
            return "In Bed"
        case .asleepUnspecified:
            return "Asleep"
        case .core:
            return "Core"
        case .deep:
            return "Deep"
        case .rem:
            return "REM"
        case .awake:
            return "Awake"
        }
    }
    
    /// 0 = highest (awake), 1 = lowest (deep)
    var depth: CGFloat {
        switch self {
        case .awake: return 1.0
        case .inBed: return 0.5
        case .asleepUnspecified: return 0.5
        case .core: return 0.33
        case .rem: return 0.66
        case .deep: return 0
        }
    }
    
    var isAsleep: Bool {
        switch self {
        case .core, .deep, .rem, .asleepUnspecified:
            return true
        default:
            return false
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .awake: return 0
        case .inBed: return 1
        case .asleepUnspecified: return 2
        case .core: return 3
        case .rem: return 4
        case .deep: return 5
        }
    }
}
