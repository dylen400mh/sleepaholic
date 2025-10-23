//
//  SoundItem.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-21.
//

import SwiftUI

// Individual sound item (64x64 tile + label)
struct SoundItem: View {
    @EnvironmentObject var windDown: WindDownManager
    let sound: String

    var selected: Bool {
        windDown.selectedSounds.contains(sound)
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                HapticsManager.play(.light)
                windDown.toggleSound(sound)
            } label: {
                ZStack {
                    if selected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.main)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Gradients.main, lineWidth: 1)
                            )
                            .overlay(
                                // 36x36 icon centered
                                Image(iconName(for: sound))
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(Gradients.main)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.main)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white5, lineWidth: 1)
                            )
                            .overlay(
                                // 36x36 icon centered
                                Image(iconName(for: sound))
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(Color.white70)
                            )
                    }
                }
                .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)

            Text(sound)
                .font(.body3)
                .foregroundColor(.white80)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func iconName(for name: String) -> String {
        switch name {
        case "White Noise": return "white_noise"
        case "Fan": return "fan"
        case "Ocean Waves": return "ocean_waves"
        case "Rain": return "rain"
        case "Crickets": return "crickets"
        case "Campfire": return "campfire"
        case "Birds": return "birds"
        case "Theta Waves": return "theta_waves"
        default: return ""
        }
    }
}
