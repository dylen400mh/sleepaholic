//
//  SettingsRow.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-25.
//

import SwiftUI

struct SettingsRow: View {
    let iconName: String
    let title: String
    var hasArrow: Bool = true
    var toggleBinding: Binding<Bool>? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.white100)
            
            Text(title)
                .font(.body1Semi)
                .foregroundColor(.white100)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let binding = toggleBinding {
                Toggle("", isOn: binding)
                    .toggleStyle(ToggleButton())
            } else if hasArrow {
                Image("right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white100)
                    .frame(width: 44, height: 24, alignment: .trailing)
            }
        }
        .contentShape(Rectangle())
    }
}
