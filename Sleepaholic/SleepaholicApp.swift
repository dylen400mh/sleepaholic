//
//  SleepaholicApp.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI
import FirebaseCore
import UserNotifications
import SuperwallKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        SuperwallService.shared.configure()
        
        // Ask for notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            } else {
                print(granted ? "✅ Notifications allowed" : "⚠️ Notifications denied")
            }
        }
        center.delegate = self   // ⬅️ AppDelegate keeps the reference alive

        return true
    }

    // Show notifications even when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📣 willPresent called for \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct SleepaholicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var windDownManager = WindDownManager.loadState()
    @StateObject private var userSettingsViewModel = UserSettingsViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var sleepLogViewModel = SleepLogViewModel()
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    @StateObject private var sleepClipViewModel = SleepClipViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingView()
            }
            .environmentObject(windDownManager)
            .environmentObject(userSettingsViewModel)
            .environmentObject(activityViewModel)
            .environmentObject(sleepLogViewModel)
            .environmentObject(userProfileViewModel)
            .environmentObject(sleepClipViewModel)
        }
    }
}


