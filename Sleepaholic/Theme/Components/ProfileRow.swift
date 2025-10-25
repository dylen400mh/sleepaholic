//
//  ProfileRow.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-25.
//

import SwiftUI

struct ProfileRow: View {
    let label: String
    var editable: Bool = false
    var keyboard: UIKeyboardType = .default
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.body1)
                .foregroundColor(.white70)
            
            Group {
                if editable {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .foregroundColor(.white100)
                        .textFieldStyle(.plain)
                } else {
                    Text(text)
                        .foregroundColor(.white70)
                }
            }
            .font(.body1Semi)
            
        }
        .contentShape(Rectangle())
    }
}
