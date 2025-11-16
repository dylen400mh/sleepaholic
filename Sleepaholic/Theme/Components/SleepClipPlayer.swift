//
//  SleepClipPlayer.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-16.
//

import SwiftUI

struct SleepClipPlayer: View {
    @StateObject private var player = AudioPlaybackManager()
    let clip: SleepClip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(clip.recordedDate?.formattedTimeHMS() ?? "Recording")
                        .foregroundColor(.white100)
                        .font(.body1Semi)
                    Text(player.isLoading ? "Loading..." : "Tap to play")
                        .foregroundColor(.white70)
                        .font(.caption)
                }

                Spacer()

                Button {
                    if player.isPlaying {
                        player.pause()
                    } else {
                        if player.hasLoaded(clip: clip) {
                            player.play()
                        } else {
                            Task { await player.loadAndPlay(storagePath: clip.storagePath) }
                        }
                    }
                } label: {
                    Image(player.isPlaying ? "pause" : "play")
                        .foregroundColor(.white100)
                        .padding(8)
                }
            }

            // Slider
            if player.duration > 0 {
                VStack(alignment: .leading) {
                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { newValue in player.seek(to: newValue) }
                        ),
                        in: 0...player.duration
                    )

                    HStack {
                        Text(timeString(player.currentTime))
                        Spacer()
                        Text(timeString(player.duration))
                    }
                    .foregroundColor(.white70)
                    .font(.caption)
                }
            }
        }
        .padding(16)
        .background(Color.white10)
        .cornerRadius(16)
    }

    private func timeString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
