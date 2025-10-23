//
//  HeaderWithSeparator.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-21.
//

import SwiftUI

// Section header with thin separator grouped (gap 4)
struct HeaderWithSeparator: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.h3Semi)
                .foregroundColor(.white100)
            Rectangle()
                .fill(Color.white20)
                .frame(height: 1)
        }
    }
}
