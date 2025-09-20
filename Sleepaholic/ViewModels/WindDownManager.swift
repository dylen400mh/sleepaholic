//
//  WindDownManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI

class WindDownManager: ObservableObject {
    @Published var isActive: Bool = false
    
    // Settings applied during wind down
    @Published var targetBedtime: Date = Date()
    @Published var targetWakeup: Date = Date()
    @Published var selectedSounds: Set<String> = []
    @Published var isPlaying: Bool = true
    @Published var trackSleep: Bool = false
    
    @Published var doNotDisturb: Bool = false
    @Published var grayscale: Bool = false
    @Published var lowBrightness: Bool = false
    @Published var restrictApps: Bool = false
    @Published var restrictedApps: [String] = ["TikTok", "Instagram", "YouTube"]
    
    // Reset everything
    func reset() {
        isActive = false
        selectedSounds.removeAll()
        isPlaying = true
        trackSleep = false
        doNotDisturb = false
        grayscale = false
        lowBrightness = false
        restrictApps = false
    }
}

