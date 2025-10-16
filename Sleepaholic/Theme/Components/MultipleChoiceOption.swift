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
                        Rectangle()
                            .fill(Gradients.main)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white100)
                            }
                    } else {
                        Rectangle()
                            .fill(Color.main)
                            .overlay {
                                Rectangle()
                                    .strokeBorder(Color.white50, lineWidth: 1.5)
                            }
                    }
                }
                .frame(width: 24, height: 24)
                .cornerRadius(6)
                
                // Option text
                Text(text)
                    .font(.body1)
                    .foregroundColor(.white100)
                
                Spacer()
            }
            .frame(width: 342, height: 56)
            .background(Color.main)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Gradients.main, lineWidth: 1.5)
            }
            .cornerRadius(12)
        }
    }
}
