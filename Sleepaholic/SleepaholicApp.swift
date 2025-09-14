//
//  SleepaholicApp.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

enum Screen: Hashable {
    case home
    case bedtime
    case wakeup
}

@main
struct SleepaholicApp: App {
    @State private var path = NavigationPath()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                ContentView()
                    .navigationDestination(for: Screen.self) { screen in
                        switch screen {
                        case .home:
                            ContentView()
                        case .bedtime:
                            BedtimeView()
                        case .wakeup:
                            WakeupView(resetToHome: {
                                path.removeLast(path.count) // 🚀 reset back to ContentView
                            })
                        }
                    }
            }
        }
    }
}

