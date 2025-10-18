//
//  MultipleChoiceOption.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct MultipleChoiceOption: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Gradients.main)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white100)
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.main)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.white50, lineWidth: 1.5)
                            }
                    }
                }
                .frame(width: 24, height: 24)

                // Option text
                Text(text)
                    .font(.body1)
                    .foregroundColor(.white100)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(16)
            .background(Color.main)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Gradients.main, lineWidth: 1.5)
                }
            }
            .cornerRadius(12)
        }
    }
}
