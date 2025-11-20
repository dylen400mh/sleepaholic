//
//  AudioSessionManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-19.
//

import AVFoundation

@MainActor
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}

    private var currentMode: Mode = .none

    enum Mode {
        case none
        case playback
        case record
        case playAndRecord
    }

    // MARK: - Public API

    func configurePlayback() {
        guard currentMode != .playback else { return }
        currentMode = .playback

        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]      // Do NOT steal audio focus
            )
            try session.setActive(true)
            print("🎧 [AudioSession] Playback-only mode activated")
        } catch {
            print("❌ Failed to set playback-only session: \(error)")
        }
    }

    func configureRecord() {
        guard currentMode != .record else { return }
        currentMode = .record

        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .record,
                mode: .default,
                options: []                     // Cleanest + safest for metering
            )

            try session.setActive(true)
            print("🎙 [AudioSession] Record-only mode activated")
        } catch {
            print("❌ Failed to set record-only session: \(error)")
        }
    }

    func configurePlayAndRecord() {
        guard currentMode != .playAndRecord else { return }
        currentMode = .playAndRecord

        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .mixWithOthers,            // Keep Spotify/YouTube unaffected
                    .allowBluetooth,           // AirPods + BT mic support
                    .defaultToSpeaker          // Play sounds out loud by default
                ]
            )

            try session.setActive(true)
            print("🎚 [AudioSession] Play-and-record mode activated")
        } catch {
            print("❌ Failed to set play-and-record session: \(error)")
        }
    }

    // MARK: - Deactivate (Optional)

    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            currentMode = .none
            print("🛑 [AudioSession] Deactivated session")
        } catch {
            print("❌ Failed to deactivate session: \(error)")
        }
    }
}
