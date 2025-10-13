//
//  AnalyticsService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-13.
//

import Foundation
import Mixpanel
import SuperwallKit

final class AnalyticsService {
    typealias Properties = [String: Any]
    typealias Event = String

    static let shared = AnalyticsService()
    private init() {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String {
            Mixpanel.initialize(token: token, trackAutomaticEvents: true)
        } else {
            fatalError("❌ Mixpanel token missing from Info.plist")
        }
    }

    // MARK: - Identify
    func identify(name: String?, userId: String, email: String) {
        let attributes: [String: Any] = [
            "name": name ?? "",
            "email": email
        ]
        
        // Mixpanel
        Mixpanel.mainInstance().identify(distinctId: userId)
        Mixpanel.mainInstance().people.set(properties: attributes as? [String: MixpanelType] ?? [:])
        
        // Superwall
        Superwall.shared.identify(userId: userId)
        Superwall.shared.setUserAttributes(attributes)
    }

    // MARK: - Update Attributes
    func updateUserAttributes(attributes: [String: Any]) {
        Mixpanel.mainInstance().people.set(properties: attributes as? [String: MixpanelType] ?? [:])
        Mixpanel.mainInstance().registerSuperProperties(attributes as? [String: MixpanelType] ?? [:])
        Superwall.shared.setUserAttributes(attributes)
    }

    // MARK: - Track Events
    func trackEvent(eventName: Event, properties: Properties? = nil) {
        Mixpanel.mainInstance().track(event: eventName, properties: properties as? [String: MixpanelType])
    }
}
