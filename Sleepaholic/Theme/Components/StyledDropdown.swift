//
//  StyledDropdown.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-24.
//

import SwiftUI

struct StyledDropdown: View {
    let label: String
    let options: [String]
    @Binding var selected: String
    @State private var showMenu = false
    @State private var isFocused = false

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.main)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
            
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
                .animation(.easeInOut(duration: 0.25), value: isFocused)
                .animation(.easeInOut(duration: 0.25), value: selected)

            HStack(spacing: 8) {
                Text(selected)
                    .font(.body1)
                    .foregroundColor(.white100)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsManager.play(.light)
                withAnimation { isFocused = true }
                showMenu = true
            }
        }
        .frame(height: 56)
        .confirmationDialog("", isPresented: $showMenu, actions: {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    withAnimation { isFocused = false }
                    selected = option
                }
            }
            Button("Cancel", role: .cancel) {
                withAnimation { isFocused = false }
            }
        })
    }
    
    // MARK: - State logic
    private var borderColor: Color {
        isFocused ? .white100 : .white50
    }

    private var borderWidth: CGFloat {
        isFocused ? 1.5 : 1
    }

    private var labelColor: Color {
        isFocused ? .white100 : .white70
    }

    private var isFloating: Bool {
        isFocused || !selected.isEmpty
    }

    private var labelOffsetY: CGFloat {
        isFloating ? -28 : 0
    }
}

