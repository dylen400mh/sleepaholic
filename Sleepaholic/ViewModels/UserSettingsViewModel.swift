//
//  UserSettingsViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import SwiftUI
import Foundation
import FirebaseAuth

@MainActor
final class UserSettingsViewModel: ObservableObject {
    @Published var settings: UserSettings?
    private let service = FirestoreService.shared
    
    private func path(for userId: String) -> String {
        return "users/\(userId)/settings"
    }
    
    private let docId = "settings"
    
    // MARK: - Local Cache (for unsigned users)
    @AppStorage("cachedBedtime") private var cachedBedtime = 0
    @AppStorage("cachedWakeUpTime") private var cachedWakeUpTime = 0
    @AppStorage("hasCachedSettings") private var hasCachedSettings = false

    func loadSettings() async {
        if let uid = Auth.auth().currentUser?.uid {
            do {
                let fetched = try await service.fetch(from: path(for: uid), id: docId) as UserSettings?
                
                if let existing = fetched {
                    settings = existing
                } else if hasCachedSettings {
                    let newSettings = UserSettings(
                        bedtime: cachedBedtime,
                        wakeUpTime: cachedWakeUpTime,
                        trackSleep: false,
                        restrictApps: false
                    )
                    
                    await saveSettings(newSettings)
                    settings = newSettings
                    
                    cachedBedtime = 0
                    cachedWakeUpTime = 0
                    hasCachedSettings = false
                }
            } catch {
                print("Error loading settings: \(error)")
            }
            return
        }
        
        if hasCachedSettings {
            settings = UserSettings(
                bedtime: cachedBedtime,
                wakeUpTime: cachedWakeUpTime,
                trackSleep: false,
                restrictApps: false
            )
        }
    }

    func saveSettings(_ settings: UserSettings) async {
        if let uid = Auth.auth().currentUser?.uid {
            do {
                try await service.save(settings, to: path(for: uid), id: docId)
                self.settings = settings
                await WindDownManager.shared.scheduleNotifications()
            } catch {
                print("Error saving settings: \(error)")
            }
        } else {
            // MARK: - No signed-in user → cache locally
            if settings.bedtime != cachedBedtime {
                cachedBedtime = settings.bedtime
            }
            if settings.wakeUpTime != cachedWakeUpTime {
                cachedWakeUpTime = settings.wakeUpTime
            }
            hasCachedSettings = true
            self.settings = settings
        }
    }
    
    func markGuidedTourCompletedIfNeeded() async {
        if var existing = settings {
            guard !existing.hasCompletedGuidedTour else { return }
            existing.hasCompletedGuidedTour = true
            await saveSettings(existing)
            return
        }
        
        await loadSettings()
        
        if var loaded = settings {
            if !loaded.hasCompletedGuidedTour {
                loaded.hasCompletedGuidedTour = true
                await saveSettings(loaded)
            }
            return
        }
        
        let fallback = UserSettings(
            bedtime: cachedBedtime,
            wakeUpTime: cachedWakeUpTime,
            trackSleep: false,
            restrictApps: false,
            hasCompletedGuidedTour: true
        )
        await saveSettings(fallback)
    }
}
