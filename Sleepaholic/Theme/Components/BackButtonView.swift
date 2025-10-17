//
//  BackButtonView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import SwiftUI

struct BackButtonView: View {
    /// Action triggered when the back button is tapped.
    let previous: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.play(.light)
            previous()
        }) {
            Image(systemName: "arrow.left")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color.white100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white40, lineWidth: 0.5)
                        .background(Color.clear)
                )
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    BackButtonView(previous: {})
}
