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

@MainActor
final class SuperwallService: NSObject, ObservableObject, SuperwallDelegate {
    static let shared = SuperwallService()
    private override init() {}
    
    private let userProfileViewModel = UserProfileViewModel()
    
    // MARK: - Configuration
    func configure() {
        guard !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") else { return }
        
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "SUPERWALL_API_KEY") as? String {
            Superwall.configure(apiKey: apiKey)
        } else {
            fatalError("❌ Superwall API key missing from Info.plist")
        }
        
        Superwall.shared.delegate = self
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
        case .transactionComplete(_, let product, _, _):
            print("💰 Transaction complete for product \(product.productIdentifier)")
        default:
            break
        }
    }
}
