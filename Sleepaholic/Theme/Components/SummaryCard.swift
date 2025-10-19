//
//  SummaryCard.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-19.
//

import SwiftUI

struct SummaryCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 8) {
            Gradients.main
                .mask(Image(systemName: icon)
                        .resizable()
                        .scaledToFit())
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.body1Semi)
                    .foregroundColor(.white100)
                Text(subtitle)
                    .font(.body3)
                    .foregroundColor(.white80)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.main80)
        .cornerRadius(12)
    }
}


