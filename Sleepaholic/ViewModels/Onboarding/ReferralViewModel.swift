//
//  ReferralViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-09.
//

import Foundation
import SwiftUI

final class ReferralViewModel: ObservableObject {
    @Published var referralCode: String = "" {
        didSet {
            AnalyticsService.shared.updateUserAttributes(attributes: ["referral_code": referralCode])
        }
    }
    
    func clear() {
        referralCode = ""
    }
}
