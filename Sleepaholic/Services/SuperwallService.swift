//
//  SuperwallService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-11.
//

import Foundation
import SuperwallKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import SwiftUI
import Combine

@MainActor
final class SuperwallService: NSObject, ObservableObject, SuperwallDelegate {
    static let shared = SuperwallService()
    private override init() {}
    
    private var cancellables = Set<AnyCancellable>()
    
    private let userProfileViewModel = UserProfileViewModel()
    
    @Published var isSubscribed: Bool = false
    
    // MARK: - Configuration
    func configure() {
        guard !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") else { return }
        
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "SUPERWALL_API_KEY") as? String else {
            fatalError("❌ Superwall API key missing from Info.plist")
        }

        let options = SuperwallOptions()
        options.shouldObservePurchases = true
        Superwall.configure(apiKey: apiKey)
        Superwall.shared.delegate = self
        
        observeSubscriptionStatus()
        
        self.isSubscribed = Superwall.shared.subscriptionStatus.isActive
        print("✅ Superwall configured — initial subscription state: \(self.isSubscribed)")
    }
    
    private func observeSubscriptionStatus() {
        Superwall.shared
            .$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Task { @MainActor in
                    self?.isSubscribed = status.isActive
                    print("🔄 Subscription status changed (published): \(self?.isSubscribed == true ? "Active" : "Inactive")")
                }
            }
            .store(in: &cancellables)
    }
    
    func subscriptionStatusDidChange(from oldValue: SubscriptionStatus, to newValue: SubscriptionStatus) {
        Task { @MainActor in
            self.isSubscribed = newValue.isActive
            print("🔄 Subscription status changed (delegate): \(self.isSubscribed ? "Active" : "Inactive")")
        }
    }
    
    // MARK: - Present Paywall
    func presentPaywall(placement: String) {
        Superwall.shared.register(placement: placement)
    }
    
    // MARK: - Handle Notification Tap
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let id = response.notification.request.identifier
        if id.contains("discount_offer") {
            // Seamlessly open discount paywall
            presentPaywall(placement: "discount_offer")
        }
    }
    
    // MARK: - Superwall Delegate
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        switch eventInfo.event {
        case .paywallOpen(_):
            print("🟢 Paywall opened")
            scheduleDiscountNotification()
        case .transactionComplete(_, let product, let transactionType, let paywallInfo):
            print("💰 Transaction complete for product \(product.productIdentifier)")

            // Safely unwrap values
            let paywallName = paywallInfo.name
            let transactionKind = transactionType.rawValue

            // Track successful purchase
            AnalyticsService.shared.trackEvent(
                eventName: "paywall_purchase_successful",
                properties: [
                    "paywall_name": paywallName,
                    "transaction_type": transactionKind,
                    "product_id": product.productIdentifier,
                    "price": product.localizedPrice,
                    "raw_price": product.price,
                    "currency": product.currencyCode ?? "",
                    "subscription_period": product.period
                ]
            )

            // Remove notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["discount_offer"])
        default:
            break
        }
    }
    
    private func scheduleDiscountNotification() {
        let key = "discountFireTime"
        guard UserDefaults.standard.object(forKey: key) == nil else { return }

        // Fetch user name for personalization
        Task {
            let userName = userProfileViewModel.profile?.name.components(separatedBy: " ").first ?? "Hey"
            
            let fireTime = Date().addingTimeInterval(300)
            UserDefaults.standard.set(fireTime, forKey: key)

            // Remove any prior notifications
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["discount_offer"])
            center.removeDeliveredNotifications(withIdentifiers: ["discount_offer"])
            
            // Create the content
            let content = UNMutableNotificationContent()
            content.title = "\(userName), we didn’t give up on you."
            content.body = "🎁⏳ Limited-time offer: Get 80% off Sleepaholic Premium and finally fix your sleep for good."
            content.sound = .default
            
            // Schedule the notification
            let interval = max(fireTime.timeIntervalSinceNow, 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: "discount_offer", content: content, trigger: trigger)
            try? await center.add(request)
            
            print("📅 Scheduled discount 5 minutes after paywall opened: \(fireTime)")
        }
    }
}
