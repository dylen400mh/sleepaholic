//
//  WindDownManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI
import Foundation
import Combine
import AVFoundation
import FirebaseStorage
import FirebaseAuth
import FamilyControls
import ManagedSettings

class WindDownManager: ObservableObject, Codable {
    static let shared = WindDownManager()
    
    // sound player
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioSessionConfigured = false
    
    // recording sleep sounds
    private var audioRecorder: AVAudioRecorder?
    private var meterRecorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private let silenceThreshold: Float = -45.0  // adjust dB level
    private let silenceDuration: TimeInterval = 3
    private var silenceStart: Date?
    
    private let store = ManagedSettingsStore()
    
    @AppStorage("bedtimeActive") private var bedtimeActive: Bool = false

    enum CodingKeys: String, CodingKey {
        case isActive, targetBedtime, targetWakeup, trackSleep,
        restrictApps, restrictedApps, selectedSounds, isPlaying
    }
    
    // Settings applied during wind down
    @Published var isActive: Bool = false {
        didSet {
            saveState()
            scheduleNotifications()
            if isActive {
                applyShield()
            } else {
                clearShield()
            }
        }
    }
    @Published var targetBedtime: Date = Date() {
        didSet {
            saveState()
            scheduleNotifications()
        }
    }
    @Published var targetWakeup: Date = Date() {
        didSet {
            saveState()
            scheduleNotifications()
        }
    }
    @Published var trackSleep: Bool = false {
        didSet {
            saveState()
        }
    }
    @Published var restrictApps: Bool = false {
        didSet
        {
            saveState()
            if isActive && restrictApps { applyShield() }
            if !restrictApps { clearShield() }
        }
    }
    @Published var restrictedApps: FamilyActivitySelection = .init() {
        didSet {
            saveState()
            if isActive && restrictApps { applyShield() }
        }
    }
    @Published var selectedSounds: Set<String> = [] { didSet { saveState() } }
    @Published var isPlaying: Bool = false { didSet { saveState() } }

    static private let storageKey = "windDownState"
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isActive = try container.decode(Bool.self, forKey: .isActive)
        targetBedtime = try container.decode(Date.self, forKey: .targetBedtime)
        targetWakeup = try container.decode(Date.self, forKey: .targetWakeup)
        trackSleep = try container.decode(Bool.self, forKey: .trackSleep)
        restrictApps = try container.decode(Bool.self, forKey: .restrictApps)
        restrictedApps = try container.decodeIfPresent(FamilyActivitySelection.self, forKey: .restrictedApps) ?? .init()
        selectedSounds = try container.decode(Set<String>.self, forKey: .selectedSounds)
        isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(isActive, forKey: .isActive)
        try container.encode(targetBedtime, forKey: .targetBedtime)
        try container.encode(targetWakeup, forKey: .targetWakeup)
        try container.encode(trackSleep, forKey: .trackSleep)
        try container.encode(restrictApps, forKey: .restrictApps)
        try container.encode(restrictedApps, forKey: .restrictedApps)
        try container.encode(selectedSounds, forKey: .selectedSounds)
        try container.encode(isPlaying, forKey: .isPlaying)
    }

    init(settings: UserSettings? = nil) {
        self.targetBedtime = settings != nil
            ? WindDownManager.dateFromMinutes(settings!.bedtime)
            : Date()
        self.targetWakeup = settings != nil
            ? WindDownManager.dateFromMinutes(settings!.wakeUpTime)
            : Date()
        self.trackSleep = settings?.trackSleep ?? false
        self.restrictApps = settings?.restrictApps ?? false
    }
    
    
    func saveState() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
        
    static func loadState() -> WindDownManager {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(WindDownManager.self, from: data),
           decoded.isActive {
            // Only restore if wind down was active
            decoded.restoreSounds()
            return decoded
        }
        // Otherwise return a fresh manager (resets sounds/settings)
        return WindDownManager()
    }

    // Reset everything back to defaults
    func reset() {
        stopAllSounds()
        isActive = false
        selectedSounds.removeAll()
        isPlaying = true
        trackSleep = false
        restrictApps = false
        
        bedtimeActive = false
    }
    
    // MARK: - Screen Time (Shielding)
    private func applyShield() {
        guard restrictApps else { return }

        // Tokens the user selected via FamilyActivityPicker
        let apps = restrictedApps.applicationTokens
        let categories = restrictedApps.categoryTokens
        let webDomains = restrictedApps.webDomainTokens

        // Apply only what’s non-empty (Apple recommends nil when unused)
        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains

        print("🛡️ Shield applied. apps=\(apps.count) categories=\(categories.count) webDomains=\(webDomains.count)")
    }


    private func clearShield() {
        store.clearAllSettings()
        print("🧹 Shield cleared.")
    }
    
    // MARK: - Helpers
    static func dateFromMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    static func minutesFromDate(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
    
    func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule wind down notification regardless of whether wind down is active or not
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: targetBedtime) ?? targetBedtime
        scheduleNotification(
            id: "winddown",
            title:"Wind Down Reminder",
            body: "Your bedtime is in 1 hour. Start your wind down routine now.",
            date: reminderDate
        )
        
        guard isActive else { return }
        
        // Schedule bedtime
        scheduleNotification(
            id: "bedtime",
            title: "Bedtime Reminder",
            body: "It’s time to go to bed.",
            date: targetBedtime
        )
        
        // Schedule wakeup
        scheduleNotification(
            id: "wakeup",
            title: "Wake Up",
            body: "Good morning! Time to start your day.",
            date: targetWakeup
        )
    }
    
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true) // repeats daily
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling \(id): \(error)")
            } else {
                print("✅ Scheduled \(id) at \(comps.hour ?? 0):\(comps.minute ?? 0)")
            }
        }
    }
    
    private func setupSharedAudioSession() {
        guard !audioSessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers]
            )
            try session.setActive(true)
            audioSessionConfigured = true
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }
    
    func playSound(named soundName: String) {
        // setup audio session so sound can be played without the app open (this only happens once then we don't need to do it again)
        setupSharedAudioSession()
        
        let possibleExtensions = ["m4a", "wav"]
        var foundURL: URL? = nil
        
        for ext in possibleExtensions {
            if let url = Bundle.main.url(forResource: soundName, withExtension: ext) {
                foundURL = url
                break
            }
        }
        
        guard let url = foundURL else {
            print("❌ Sound file \(soundName) not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // loop indefinitely
            player.prepareToPlay()
            player.play()
            audioPlayers[soundName] = player
            resumeAllSounds() // play other sounds if we paused
        } catch {
            print("❌ Could not play sound \(soundName): \(error)")
        }
    }

    func stopSound(named soundName: String) {
        if let player = audioPlayers[soundName] {
            player.stop()
            audioPlayers.removeValue(forKey: soundName)
        }
    }

    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
        audioPlayers.removeAll()
        isPlaying = false
    }
    
    func pauseAllSounds() {
        for (_, player) in audioPlayers {
            player.pause()
        }
        isPlaying = false
    }

    func resumeAllSounds() {
        for (_, player) in audioPlayers {
            player.play()
        }
        isPlaying = true
    }
    
    func toggleSound(_ soundName: String) {
        if selectedSounds.contains(soundName) {
            selectedSounds.remove(soundName)
            stopSound(named: soundName)
        } else {
            selectedSounds.insert(soundName)
            playSound(named: soundName)
        }
    }
    
    func restoreSounds() {
        setupSharedAudioSession()
        
        for sound in selectedSounds {
            guard audioPlayers[sound] == nil else { continue }

            let possibleExtensions = ["m4a", "wav"]
            var foundURL: URL? = nil
            for ext in possibleExtensions {
                if let url = Bundle.main.url(forResource: sound, withExtension: ext) {
                    foundURL = url
                    break
                }
            }
            guard let url = foundURL else { continue }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.prepareToPlay()
                audioPlayers[sound] = player

                if isPlaying {
                    player.play() // only autoplay if previously playing
                }
            } catch {
                print("❌ Could not restore sound \(sound): \(error)")
            }
        }
    }
    
    func startMonitoringSleep(logPath: String) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupSharedAudioSession()
                    self.setupMeterRecorder()
                    self.meterTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                        self?.checkAudioLevel(logPath: logPath)
                    }
                    print("🎧 Sleep monitoring started")
                } else {
                    print("🚫 Microphone permission denied — sleep tracking not started.")
                }
            }
        }
    }

    func stopMonitoringSleep(logPath: String) {
        meterTimer?.invalidate()
        meterTimer = nil
        stopRecordingClip(logPath: logPath)
        meterRecorder?.stop()
        meterRecorder = nil
        deactivateRecordingSession()
    }
    
    private func deactivateRecordingSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            audioSessionConfigured = false
        } catch {
            print("❌ Could not deactivate recording session: \(error)")
        }
    }

    private func startRecordingClip(logPath: String) {
        let filename = "\(UUID().uuidString).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            print("🎙 Started recording \(filename)")
        } catch {
            print("❌ Failed to start recording: \(error)")
        }
    }

    private func stopRecordingClip(logPath: String) {
        guard let recorder = audioRecorder else { return }
        recorder.stop()
        let url = recorder.url
        audioRecorder = nil
        print("⏹️ Stopped recording clip at \(url)")
        
        // Build storage path
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        let storagePath = "\(logPath)/clips/\(timestamp).m4a"
        
        let storageRef = Storage.storage().reference().child(storagePath)
        
        // Upload the file
        storageRef.putFile(from: url, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Upload failed: \(error)")
            } else {
                print("✅ Clip uploaded to \(storagePath)")
            }
        }
    }
    
    private func setupMeterRecorder() {
        let url = URL(fileURLWithPath: "/dev/null") // throwaway file
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            meterRecorder = try AVAudioRecorder(url: url, settings: settings)
            meterRecorder?.isMeteringEnabled = true
            meterRecorder?.record()
        } catch {
            print("❌ Failed to start meter recorder: \(error)")
        }
    }

    private func checkAudioLevel(logPath: String) {
        if let recorder = audioRecorder {
            // already recording → check for silence
            recorder.updateMeters()
            let avg = recorder.averagePower(forChannel: 0)

            if avg < silenceThreshold {
                if silenceStart == nil { silenceStart = Date() }
                if let start = silenceStart,
                   Date().timeIntervalSince(start) > silenceDuration {
                    stopRecordingClip(logPath: logPath)
                    silenceStart = nil
                }
            } else {
                silenceStart = nil
            }
        } else if let meter = meterRecorder {
            // not recording → check if loud enough to start
            meter.updateMeters()
            let avg = meter.averagePower(forChannel: 0)
            if avg >= silenceThreshold {
                startRecordingClip(logPath: logPath)
            }
        }
    }
}


