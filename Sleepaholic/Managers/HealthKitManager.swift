//
//  HealthKitManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-15.
//

import Foundation
import HealthKit

/// Singleton manager responsible for interacting with Apple Health.
final class HealthKitManager {
    
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // MARK: - Permission
    
    /// Requests sleep data read permission.
    func requestAuthorization() async -> Void {
        let types = Set([
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ])

        do {
            if HKHealthStore.isHealthDataAvailable() {
                try await healthStore.requestAuthorization(toShare: types, read: types)
            }
        } catch {
            print("❌ HealthKit authorization failed: \(error)")
        }
    }

    /// Checks whether the app currently has permission to read sleep data.
    func isAuthorized() -> Bool {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return false
        }
        
        let status = healthStore.authorizationStatus(for: sleepType)
        return status == .sharingAuthorized
    }
    
    // MARK: - Fetch Sleep Data
    
    /// Fetches sleep segments for a specific date.
    /// Converts raw HK samples into our SleepSegment struct.
    func fetchSleepSegments(for date: Date) async throws -> [SleepSegment] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataTypeUnavailable
        }

        let calendar = Calendar.current
        
        let dayStart = calendar.startOfDay(for: date)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: dayStart)!
        let endOfToday = calendar.date(byAdding: .second, value: -1,
            to: calendar.date(byAdding: .day, value: 1, to: dayStart)!)!

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterdayStart,
            end: endOfToday,
            options: []
        )

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results as? [HKCategorySample] ?? [])
                }
            }

            self.healthStore.execute(query)
        }

        // Convert into SleepSegment models
        let segments = samples.compactMap(mapSampleToSegment)
        
        return segments.sorted { $0.start < $1.start }
    }
    
    /// Fetches sleep segments within a date range.
    /// Useful for future weekly/monthly reports.
    func fetchSleepSegments(from start: Date, to end: Date) async throws -> [SleepSegment] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataTypeUnavailable
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results as? [HKCategorySample] ?? [])
                }
            }

            self.healthStore.execute(query)
        }

        let segments = samples.compactMap(mapSampleToSegment)
        
        return segments.sorted(by: { $0.start < $1.start })
    }
    
    // MARK: - Helpers
    
    /// Map HKCategorySample → SleepSegment.
    private func mapSampleToSegment(_ sample: HKCategorySample) -> SleepSegment? {
        let stage: SleepStage
            
        switch sample.value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            stage = .inBed
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            stage = .awake
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            stage = .core
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            stage = .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            stage = .rem
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            stage = .asleepUnspecified
        default:
            return nil
        }
        
        return SleepSegment(
            start: sample.startDate,
            end: sample.endDate,
            stage: stage
        )
    }
}

enum HealthKitError: Error {
    case notAvailableOnDevice
    case dataTypeUnavailable
}
