//
//  Gradients.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-14.
//

import SwiftUI

struct Gradients {
    static let main = LinearGradient(
        colors: [Color.gradientStart, Color.gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
