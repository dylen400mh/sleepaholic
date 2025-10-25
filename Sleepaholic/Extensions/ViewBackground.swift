//
//  ViewBackground.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-16.
//

import SwiftUI

struct GlobalBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            BackgroundView()
            content
        }
    }
}

extension View {
    func appBackground() -> some View {
        self.modifier(GlobalBackground())
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
