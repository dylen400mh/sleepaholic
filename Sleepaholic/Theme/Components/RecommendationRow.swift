//
//  RecommendationRow.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-01.
//

import SwiftUI

struct RecommendationRow: View {
    let recommendation: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.square")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white100)
            Text(recommendation)
                .font(.body2)
                .foregroundColor(.white100)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white5)
        .cornerRadius(12)
    }
}


