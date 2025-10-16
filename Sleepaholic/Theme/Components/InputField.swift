//
//  InputField.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct InputField: View {
    let label: String
    @Binding var text: String
    var error: String? = nil
    
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Floating label
            Text(label)
                .font(.body3)
                .foregroundColor(labelColor)
                .padding(.leading, 16)
                .padding(.top, text.isEmpty ? 16 : 4)
                .animation(.easeInOut(duration: 0.2), value: text)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // TextField background & border
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.main)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    )
                    .frame(height: 56)
                
                TextField("", text: $text)
                    .font(.body1)
                    .foregroundColor(.white100)
                    .padding(.horizontal, 16)
                    .focused($isFocused)
                    .frame(height: 56)
            }
            
            // Error text
            if let error = error {
                Text(error)
                    .font(.body3)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                    .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    // MARK: - Computed Colors
    private var borderColor: Color {
        if error != nil { return .red }
        return isFocused ? .white100 : .white50
    }

    private var borderWidth: CGFloat {
        if error != nil { return 1.5 }
        return isFocused ? 1.5 : 1
    }

    private var labelColor: Color {
        if error != nil { return .red }
        return isFocused ? .white100 : .white70
    }
}
