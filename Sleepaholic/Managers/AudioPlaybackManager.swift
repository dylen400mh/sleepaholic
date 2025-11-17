//
//  AudioPlaybackManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-16.
//

import Foundation
import AVFoundation
import FirebaseStorage

@MainActor
final class AudioPlaybackManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var loadedPath: String?

    func hasLoaded(clip: SleepClip) -> Bool {
        loadedPath == clip.storagePath
    }
    
    // MARK: - Load & Play
    func loadAndPlay(storagePath: String) async {
        if loadedPath == storagePath {
            play()
            return
        }
        
        stop()  // stop any previous playback
        loadedPath = storagePath
        isLoading = true

        do {
            let url = try await downloadFromFirebase(path: storagePath)
            try preparePlayer(url: url)
            play()
        } catch {
            print("❌ Failed to load audio: \(error)")
        }

        isLoading = false
    }

    private func preparePlayer(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        duration = player?.duration ?? 0
    }

    // MARK: - Controls
    func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        player?.stop()
        isPlaying = false
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    // MARK: - Timer for UI updates
    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }

            Task { @MainActor in
                guard let player = self.player else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.isPlaying = false
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Firebase helper
    private func downloadFromFirebase(path: String) async throws -> URL {
        let ref = Storage.storage().reference(withPath: path)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")

        _ = try await ref.writeAsync(toFile: tempURL)
        return tempURL
    }
}
