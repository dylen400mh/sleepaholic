//
//  ToggleButton.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct ToggleButton: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            GeometryReader { geometry in
                let width: CGFloat = 44
                let height: CGFloat = 24
                let circleSize: CGFloat = 18
                let circleOffset: CGFloat = 11

                ZStack {
                    // Background
                    if configuration.isOn {
                        Gradients.main
                    } else {
                        Color.white10
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .strokeBorder(Color.white40, lineWidth: 1)
                            )
                    }

                    // Circle thumb
                    Group {
                        if configuration.isOn {
                            Circle()
                                .fill(Color.white100)
                        } else {
                            Circle()
                                .fill(Gradients.main)
                        }
                    }
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: configuration.isOn ? circleOffset : -circleOffset)
                    .animation(.spring(response: 0.2), value: configuration.isOn)
                }
            }
            .frame(width: 44, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
    }
}
