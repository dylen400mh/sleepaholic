//
//  OnboardingAudioManager.swift
//  Sleepaholic
//
//  Created by OpenAI Codex on 2025-02-15.
//

import Foundation
import AVFoundation

@MainActor
final class OnboardingAudioManager: ObservableObject {
    private let soundNames = ["crickets", "campfire"]
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioSessionConfigured = false
    private var isPlaying = false

    func start() {
        guard !isPlaying else { return }

        configureAudioSessionIfNeeded()

        for sound in soundNames {
            guard audioPlayers[sound] == nil else { continue }
            if let player = makePlayer(for: sound) {
                player.numberOfLoops = -1
                player.prepareToPlay()
                player.play()
                audioPlayers[sound] = player
            }
        }

        isPlaying = !audioPlayers.isEmpty
    }

    func stop() {
        guard isPlaying else { return }

        for (_, player) in audioPlayers {
            player.stop()
        }
        audioPlayers.removeAll()
        isPlaying = false

        deactivateAudioSession()
    }

    private func makePlayer(for resourceName: String) -> AVAudioPlayer? {
        let possibleExtensions = ["m4a", "wav"]
        var resourceURL: URL? = nil

        for ext in possibleExtensions {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: ext) {
                resourceURL = url
                break
            }
        }

        guard let url = resourceURL else {
            print("❌ Onboarding sound \(resourceName) not found in bundle.")
            return nil
        }

        do {
            return try AVAudioPlayer(contentsOf: url)
        } catch {
            print("❌ Failed to create AVAudioPlayer for \(resourceName): \(error)")
            return nil
        }
    }

    private func configureAudioSessionIfNeeded() {
        guard !audioSessionConfigured else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            audioSessionConfigured = true
        } catch {
            print("❌ Failed to configure onboarding audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        guard audioSessionConfigured else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("⚠️ Failed to deactivate onboarding audio session: \(error)")
        }
        audioSessionConfigured = false
    }
}
