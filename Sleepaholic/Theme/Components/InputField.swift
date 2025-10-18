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
            ZStack(alignment: .leading) {
                // MARK: - Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.main)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    )
                
                // Label
                Text(label)
                    .font(isFloating ? .body3 : .body1)
                    .foregroundColor(labelColor)
                    .padding(.horizontal, isFloating ? 8 : 0)
                    .background(
                        isFloating ?
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.main)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                        : nil
                    )
                    .offset(x: 16, y: labelOffsetY)
                    .scaleEffect(isFloating ? 1.0 : 1.0, anchor: .leading)
                    .animation(.easeInOut(duration: 0.25), value: isFocused)
                    .animation(.easeInOut(duration: 0.25), value: text)
                
                TextField("", text: $text)
                    .font(.body1)
                    .foregroundColor(.white100)
                    .padding(.horizontal, 16)
                    .focused($isFocused)
                    .zIndex(1)
            }
            .frame(height: 56)
            .onTapGesture { isFocused = true }
            
            if let error = error {
                Text(error)
                    .font(.body3)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                    .padding(.bottom, -20)
            }
        }
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
    
    private var isFloating: Bool {
            isFocused || !text.isEmpty
        }

    private var labelOffsetY: CGFloat {
        isFloating ? -28 : 0
    }
}
