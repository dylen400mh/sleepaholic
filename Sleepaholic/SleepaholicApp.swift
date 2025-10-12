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

enum QuickAction: String {
    case sendFeedback = "com.sleepaholic.sendFeedback"
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var pendingQuickAction: QuickAction?
    
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
    
    // MARK: - Quick Action handling

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = handle(shortcutItem: shortcutItem)
        completionHandler(handled)
    }

    @discardableResult
    private func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(rawValue: shortcutItem.type) else { return false }
        AppDelegate.pendingQuickAction = action

        // Notify SwiftUI (warm app)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .didTriggerQuickAction,
                object: nil,
                userInfo: ["action": action]
            )
        }
        return true
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
}

extension Notification.Name {
    static let didTriggerQuickAction = Notification.Name("didTriggerQuickAction")
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
    
    private let feedbackFormURL = URL(string: "https://forms.gle/sleepaholic-feedback")!
    
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
            .onReceive(NotificationCenter.default.publisher(for: .didTriggerQuickAction)) { note in
                if let action = (note.userInfo?["action"] as? QuickAction) ?? AppDelegate.pendingQuickAction {
                    AppDelegate.pendingQuickAction = nil
                    handleQuickAction(action)
                }
            }
        }
    }
    
    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .sendFeedback:
            openURL(feedbackFormURL)
        }
    }
}


