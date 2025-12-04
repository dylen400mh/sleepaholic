//
//  SleepReflection.swift
//  Sleepaholic
//
//  Created by John on 2025-12-02.
//

import Foundation
import FirebaseFirestore

enum ReflectionMood: String, Codable, CaseIterable, Equatable {
    case great
    case okay
    case rough
}

enum ReflectionScheduleConsistency: String, Codable, Equatable {
    case onSchedule
    case offSchedule
}

struct SleepReflection: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var dayKey: String      // yyyy-MM-dd string keyed to a 4am boundary
    var recordedAt: Date
    
    var sleepQuality: ReflectionMood
    var morningFeeling: ReflectionMood
    var scheduleConsistency: ReflectionScheduleConsistency
}
