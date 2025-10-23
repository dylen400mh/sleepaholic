//
//  MixCard.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-21.
//

import SwiftUI

struct MixCard: View {
    let sounds: Set<String>
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Left: labels
            VStack(alignment: .leading, spacing: 0) {
                Text("Your mix")
                    .font(.body3)
                    .foregroundColor(Color.white100)
                Text(sounds.joined(separator: ", "))
                    .font(.body3)
                    .foregroundColor(Color.white80)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Icons (overlapping)
            HStack(spacing: -16) {
                ForEach(Array(sounds.prefix(4).enumerated()), id: \.offset) { _, s in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.main)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white5, lineWidth: 1)
                        )
                        .overlay(
                            Image(iconName(for: s))
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 22.5, height: 22.5)
                                .foregroundStyle(Gradients.main)
                        )
                        .frame(width: 40, height: 40)
                }
            }

            Button(action: onPlayPause) {
                Image(isPlaying ? "pause" : "play")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Button(action: onStop) {
                Image("x")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white5)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
