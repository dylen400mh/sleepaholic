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
import UIKit
import Mixpanel
import FirebaseAuth

enum QuickAction: String {
    case sendFeedback = "com.sleepaholic.sendFeedback"
}

@MainActor
final class SceneDelegate: NSObject, UIWindowSceneDelegate {

    // Called on cold launch when the app is opened via a quick action
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcutItem = connectionOptions.shortcutItem {
            // Cache for SwiftUI to consume once UI is ready
            AppDelegate.pendingQuickAction = QuickAction(rawValue: shortcutItem.type)
            // Also post for warm-ish cases
            NotificationCenter.default.post(
                name: .didTriggerQuickAction,
                object: nil,
                userInfo: ["action": AppDelegate.pendingQuickAction as Any]
            )
        }
    }

    // Called when app is already running (warm) and the user picks a quick action
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        let handled = QuickAction(rawValue: shortcutItem.type) != nil
        if let action = QuickAction(rawValue: shortcutItem.type) {
            AppDelegate.pendingQuickAction = action
            NotificationCenter.default.post(
                name: .didTriggerQuickAction,
                object: nil,
                userInfo: ["action": action]
            )
        }
        completionHandler(handled)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var pendingQuickAction: QuickAction?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // init Analytics
        _ = AnalyticsService.shared
        
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
        
        updateQuickActions(for: application)

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
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Forward to SuperwallService when a discount notification is tapped
        SuperwallService.shared.handleNotificationResponse(response)
        completionHandler()
    }
    
    private func updateQuickActions(for application: UIApplication) {
        let feedbackItem = UIApplicationShortcutItem(
            type: QuickAction.sendFeedback.rawValue,
            localizedTitle: "Deleting? Tell us why.",
            localizedSubtitle: "Send quick feedback before deleting",
            icon: UIApplicationShortcutIcon(systemImageName: "square.and.pencil")
        )

        application.shortcutItems = [feedbackItem]
    }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self   // 👈 This connects your SceneDelegate!
        return config
    }
}

extension Notification.Name {
    static let didTriggerQuickAction = Notification.Name("didTriggerQuickAction")
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

@main
struct SleepaholicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.openURL) private var openURL
    
    @StateObject private var windDownManager = WindDownManager.loadState()
    @StateObject private var userSettingsViewModel = UserSettingsViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var sleepLogViewModel = SleepLogViewModel()
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    @StateObject private var sleepClipViewModel = SleepClipViewModel()
    
    private let feedbackFormURL = URL(string: "https://forms.gle/r9qt8PP5YFs8SzWSA")!
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashScreenView()
                    .appBackground()
            }
            .id(AuthService.shared.currentUser?.uid ?? "signed-out")
            .environmentObject(windDownManager)
            .environmentObject(userSettingsViewModel)
            .environmentObject(activityViewModel)
            .environmentObject(sleepLogViewModel)
            .environmentObject(userProfileViewModel)
            .environmentObject(sleepClipViewModel)
            .onReceive(NotificationCenter.default.publisher(for: .didTriggerQuickAction)) { note in
                if let action = (note.userInfo?["action"] as? QuickAction) ?? AppDelegate.pendingQuickAction {
                    AppDelegate.pendingQuickAction = nil
                    handleQuickAction(action)
                }
            }
            .onAppear {
                consumePendingQuickActionIfAny()
                preloadUserProfileIfNeeded()
                identifyCurrentUserIfNeeded()
            }
        }
    }
    
    @MainActor private func consumePendingQuickActionIfAny() {
        if let action = AppDelegate.pendingQuickAction {
            AppDelegate.pendingQuickAction = nil
            handleQuickAction(action)
        }
    }
    
    @MainActor
    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .sendFeedback:
            openURL(feedbackFormURL)
        }
    }
    
    @MainActor
    private func preloadUserProfileIfNeeded() {
        Task {
            if Auth.auth().currentUser != nil {
                await userProfileViewModel.loadProfile()
                await userSettingsViewModel.loadSettings()
                print("📄 User profile preloaded at app launch.")
            } else {
                print("ℹ️ No signed-in user; skipping profile preload.")
            }
        }
    }
    
    @MainActor
    private func identifyCurrentUserIfNeeded() {
        if let user = Auth.auth().currentUser {
            AnalyticsService.shared.identify(
                name: user.displayName,
                userId: user.uid,
                email: user.email ?? ""
            )
            print("📊 Re-identified existing user for analytics: \(user.uid)")
        } else {
            print("ℹ️ No logged-in user found at launch (anonymous session).")
        }
    }
}


