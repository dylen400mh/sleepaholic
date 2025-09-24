//
//  SleepaholicApp.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
    AuthService.shared.signInAnonymously()

    return true
  }
}

@main
struct SleepaholicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var windDownManager = WindDownManager()
    @StateObject private var userSettingsViewModel = UserSettingsViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var sleepLogViewModel = SleepLogViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(windDownManager)
            .environmentObject(userSettingsViewModel)
            .environmentObject(activityViewModel)
            .environmentObject(sleepLogViewModel)
        }
    }
}


