//
//  Dropdown.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct Dropdown: View {
    let label: String
    let options: [String]
    
    @Binding var selection: String?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Floating label (visible only when selected)
            if selection != nil {
                Text(label)
                    .font(.body3)
                    .foregroundColor(.white70)
                    .padding(.leading, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Main dropdown button
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    // Display text
                    Text(selection ?? label)
                        .font(.body1)
                        .foregroundColor(selection == nil ? .white70 : .white100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Chevron icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white100)
                }
                .padding(.horizontal, 16)
                .frame(width: 342, height: 56)
                .background(Color.main)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isExpanded ? Color.white100 : Color.white50,
                            lineWidth: isExpanded ? 1.5 : 1
                        )
                )
            }
            
            // Dropdown options
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        MultipleChoiceOption(
                            text: option,
                            isSelected: selection == option
                        ) {
                            selection = option
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
