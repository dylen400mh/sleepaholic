//
//  SleepaholicApp.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

@main
struct SleepaholicApp: App {
    @StateObject private var windDownManager = WindDownManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(windDownManager)
        }
    }
}


