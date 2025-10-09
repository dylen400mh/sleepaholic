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
        HStack {
            Button(action: {
                HapticsManager.play(.light)
                previous()
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(8)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    BackButtonView(previous: {})
}
