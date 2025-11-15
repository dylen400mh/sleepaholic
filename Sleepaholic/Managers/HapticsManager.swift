//
//  HapticsManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import Foundation
import UIKit
import CoreHaptics

enum HapticType {
    case light, medium, heavy, success, warning, error
}

struct HapticsManager {
    static func play(_ type: HapticType) {
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
