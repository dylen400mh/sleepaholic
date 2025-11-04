//
//  AdaptiveSpacing.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-03.
//

import SwiftUI

struct AdaptiveVerticalPaddingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 60 // default for iPhone
}

extension EnvironmentValues {
    var adaptiveVerticalPadding: CGFloat {
        get { self[AdaptiveVerticalPaddingKey.self] }
        set { self[AdaptiveVerticalPaddingKey.self] = newValue }
    }
}

struct AdaptiveVerticalPaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var hSize

    func body(content: Content) -> some View {
        let value: CGFloat = (hSize == .regular) ? 500 : 60 // iPad vs iPhone
        return content.environment(\.adaptiveVerticalPadding, value)
    }
}

extension View {
    func enableAdaptivePadding() -> some View {
        self.modifier(AdaptiveVerticalPaddingModifier())
    }
}

