//
//  Shadows.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-14.
//

import SwiftUI

// MARK: - Shadow Config
struct ShadowStyleConfig {
    let color: Color
    let blur: CGFloat
    let x: CGFloat
    let y: CGFloat
    let spread: CGFloat
}

// MARK: - Preset Shadows
struct ShadowStyle {
    // Elevation shadow (used for buttons, cards, etc.)
    static let elevation = ShadowStyleConfig(
        color: Color.shadow.opacity(0.4),
        blur: 16,
        x: 0,
        y: 0,
        spread: 0
    )

    // Checkbox shadow
    static let checkBox = ShadowStyleConfig(
        color: Color.dark.opacity(0.3),
        blur: 0,
        x: 0,
        y: 0,
        spread: 4
    )
}

// MARK: - Apply Shadow Modifier
extension View {
    func applyShadow(_ config: ShadowStyleConfig) -> some View {
        self
            .shadow(color: config.color, radius: config.blur, x: config.x, y: config.y)
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .shadow(color: config.color,
                                radius: max(0, config.spread),
                                x: config.x,
                                y: config.y)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: -config.spread)
                        )
                        .opacity(config.spread > 0 ? 1 : 0)
                }
            )
    }
}
