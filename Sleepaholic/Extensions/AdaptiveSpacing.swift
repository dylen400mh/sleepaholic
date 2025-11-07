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
        let bottomInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0

        let adaptivePadding: CGFloat = bottomInset == 0
        ? 100
        : 40 + (bottomInset * 0.5)

        return content.environment(\.adaptiveVerticalPadding, adaptivePadding)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension View {
    func enableAdaptivePadding() -> some View {
        self.modifier(AdaptiveVerticalPaddingModifier())
    }
}

