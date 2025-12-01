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
import DeviceActivity

@MainActor
class WindDownManager: ObservableObject {
    static private let storageKey = "windDownState"
    
    private struct PersistedState: Codable {
        var restrictedApps: FamilyActivitySelection
        var selectedSounds: Set<String>
        var isPlaying: Bool
    }
    
    static let shared: WindDownManager = {
        let manager = WindDownManager()
        
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) {
            manager.restrictedApps = decoded.restrictedApps
            manager.selectedSounds = decoded.selectedSounds
            manager.isPlaying = decoded.isPlaying
            manager.prepareAudioSessionForCurrentState()
            manager.restoreSounds()
            
            if manager.bedtimeActive, let existingPath = manager.logPath {
                manager.restartMonitoringAfterRelaunch(logPath: existingPath)
            }
        }
        
        return manager
    }()
    
    weak var userSettingsViewModel: UserSettingsViewModel?
    
    func bindUserSettings(_ vm: UserSettingsViewModel) {
        self.userSettingsViewModel = vm
    }
    
    // sound player
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    // recording sleep sounds
    private var audioRecorder: AVAudioRecorder?
    private var meterRecorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private let silenceThreshold: Float = -45.0  // adjust dB level
    private let silenceDuration: TimeInterval = 3
    private var silenceStart: Date?
    
    @AppStorage("logPath") private var logPath: String?
    
    @AppStorage("bedtimeActive") private var bedtimeActive: Bool = false

    enum CodingKeys: String, CodingKey {
        case restrictedApps, selectedSounds, isPlaying
    }
    
    @Published var restrictedApps: FamilyActivitySelection = .init() {
        didSet {
            saveState()
            
            if let data = try? JSONEncoder().encode(restrictedApps) {
                UserDefaults(suiteName: "group.sleepaholic")?
                    .set(data, forKey: "shieldSelection")
            }
            
            ShieldController.shared.latestSelection = restrictedApps
            
            Task { @MainActor in
                guard let settings = userSettingsViewModel?.settings else { return }
                
                // read latest toggle value safely on the main actor
                if settings.restrictApps == true, WindDownManager.isNowInRestrictionWindow(settings: settings) {
                    ShieldController.shared.applyShield()
                } else {
                    ShieldController.shared.clearShield()
                }
                
            }
        }
    }
    @Published var selectedSounds: Set<String> = [] { didSet { saveState() } }
    @Published var isPlaying: Bool = false { didSet { saveState() } }

    init() {}
    
    func saveState() {
        let state = PersistedState(
            restrictedApps: restrictedApps,
            selectedSounds: selectedSounds,
            isPlaying: isPlaying
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // Reset everything back to defaults
    func reset() {
        stopAllSounds()
        stopMonitoringSleep()
        selectedSounds.removeAll()
        isPlaying = true
        bedtimeActive = false
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
    
    static func isNowInRestrictionWindow(settings: UserSettings) -> Bool {
        let now = Date()

        let bedtime = dateFromMinutes(settings.bedtime)
        let windDownStart = Calendar.current.date(byAdding: .hour, value: -1, to: bedtime) ?? bedtime
        let wakeDate = dateFromMinutes(settings.wakeUpTime)

        // Handles crossing midnight correctly
        if windDownStart <= wakeDate {
            return now >= windDownStart && now <= wakeDate
        } else {
            return now >= windDownStart || now <= wakeDate
        }
    }
    
    func scheduleNotifications() async {
        guard let settings = await MainActor.run(body: { userSettingsViewModel?.settings }) else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let targetBedtime = WindDownManager.dateFromMinutes(settings.bedtime)
        let targetWakeup = WindDownManager.dateFromMinutes(settings.wakeUpTime)
        
        // Schedule wind down notification
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: targetBedtime) ?? targetBedtime
        scheduleNotification(
            id: "winddown",
            title:"Wind Down Reminder",
            body: "Your bedtime is in 1 hour. Start your wind down routine now.",
            date: reminderDate
        )
        
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
    
    func playSound(named soundName: String) {
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
            
            if selectedSounds.isEmpty {
                AudioSessionManager.shared.deactivate()
            }
        } else {
            AudioSessionManager.shared.configurePlayback()
            selectedSounds.insert(soundName)
            playSound(named: soundName)
        }
    }
    
    func restoreSounds() {
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
    
    func startMonitoringSleep(logPath: String) async {
        let shouldTrack = await MainActor.run(body: { userSettingsViewModel?.settings?.trackSleep == true })
        guard shouldTrack else { return }
        
        self.logPath = logPath
        
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    AudioSessionManager.shared.configurePlayAndRecord()
                    self.setupMeterRecorder()
                    self.meterTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.checkAudioLevel(logPath: logPath)
                        }
                    }
                    print("🎧 Sleep monitoring started")
                } else {
                    if self.isPlaying {
                        AudioSessionManager.shared.configurePlayback()
                    }
                    print("🚫 Microphone permission denied — sleep tracking not started.")
                }
            }
        }
    }

    func stopMonitoringSleep() {
        meterTimer?.invalidate()
        meterTimer = nil
        if let path = logPath {
            stopRecordingClip(logPath: path)
        }
        meterRecorder?.stop()
        meterRecorder = nil
        AudioSessionManager.shared.deactivate()
        logPath = nil
    }
    
    func restartMonitoringAfterRelaunch(logPath: String) {
        AudioSessionManager.shared.configurePlayAndRecord()
        setupMeterRecorder()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.checkAudioLevel(logPath: logPath)
            }
        }
        
        print("🔄 Monitoring resumed after relaunch")
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
    
    func prepareAudioSessionForCurrentState() {
        if bedtimeActive {
            // User reopened the app while bedtime was active → sleep monitoring resumed
            AudioSessionManager.shared.configurePlayAndRecord()
        } else if !selectedSounds.isEmpty {
            // User had sounds selected → restore playback
            AudioSessionManager.shared.configurePlayback()
        } else {
            AudioSessionManager.shared.deactivate()
        }
    }
}

extension WindDownManager {
    func updateDeviceActivitySchedule() async {
        guard let settings = await MainActor.run(body: { userSettingsViewModel?.settings }) else {
            return
        }

        let center = DeviceActivityCenter()
        
        // If OFF → stop monitoring
        if settings.restrictApps == false {
            center.stopMonitoring()
            ShieldController.shared.clearShield()
            print("⏹ DeviceActivity: stopped monitoring")
            return
        }

        // Convert your minutes → DateComponents (required)
        let bedtime = settings.bedtime
        let wake = settings.wakeUpTime

        let restrictionStart = (bedtime - 60 + 1440) % 1440

        let startComponents = DateComponents(
            calendar: Calendar.current,
            hour: restrictionStart / 60,
            minute: restrictionStart % 60
        )

        let endComponents = DateComponents(
            calendar: Calendar.current,
            hour: wake / 60,
            minute: wake % 60
        )

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true   // NOT .daily — it's literally a Bool
        )

        do {
            try center.startMonitoring(
                DeviceActivityName("sleepaholic_schedule"),
                during: schedule
            )
            print("📆 DeviceActivity: schedule updated")
        } catch {
            print("❌ Failed to update schedule: \(error)")
        }
        
        // Enforce correct shield state immediately
        let inWindow = WindDownManager.isNowInRestrictionWindow(settings: settings)

        if inWindow {
            ShieldController.shared.applyShield()
            print("🛡️ Immediate applyShield (inside restriction window)")
        } else {
            ShieldController.shared.clearShield()
            print("🧹 Immediate clearShield (outside restriction window)")
        }
    }
    
    var restrictionStartText: String {
        guard let settings = userSettingsViewModel?.settings else { return "" }
        let start = (settings.bedtime - 60 + 1440) % 1440
        let date = WindDownManager.dateFromMinutes(start)
        return date.formatted(date: .omitted, time: .shortened)
    }

    var restrictionEndText: String {
        guard let settings = userSettingsViewModel?.settings else { return "" }
        let date = WindDownManager.dateFromMinutes(settings.wakeUpTime)
        return date.formatted(date: .omitted, time: .shortened)
    }

    var isRestrictionActiveNow: Bool {
        guard let settings = userSettingsViewModel?.settings else { return false }
        return WindDownManager.isNowInRestrictionWindow(settings: settings)
    }
}
