//
//  SleepReflectionViewModel.swift
//  Sleepaholic
//
//  Created by John on 2025-12-02.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SleepReflectionViewModel: ObservableObject {
    enum Step: Int {
        case sleepQuality
        case morningFeeling
        case scheduleConsistency
    }
    
    enum Trigger {
        case loggedSleep
        case dailyOpen
    }
    
    @Published var isPresenting: Bool = false
    @Published var currentStep: Step = .sleepQuality
    
    @Published var sleepQuality: ReflectionMood?
    @Published var morningFeeling: ReflectionMood?
    @Published var scheduleConsistency: ReflectionScheduleConsistency?
    
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    @AppStorage("lastReflectionPromptDayKey") private var lastPromptDayKey: String?
    @AppStorage("lastReflectionCompletedDayKey") private var lastCompletedDayKey: String?
    
    private let service = FirestoreService.shared
    private let collection = "sleepReflections"
    
    // MARK: - Public API
    func evaluateDailyReminder(activeSleepLog: SleepLog?) async {
        guard activeSleepLog == nil else { return } // do not interrupt an active sleep session
        await presentIfNeeded(trigger: .dailyOpen)
    }
    
    func presentAfterLoggedSleep(activeSleepLog: SleepLog?) async {
        guard activeSleepLog == nil else { return }
        await presentIfNeeded(trigger: .loggedSleep)
    }
    
    func skipForToday() {
        let key = Self.dayKey(for: Date())
        lastPromptDayKey = key
        isPresenting = false
        resetSelections()
    }
    
    func selectSleepQuality(_ mood: ReflectionMood) {
        sleepQuality = mood
        advance()
    }
    
    func selectMorningFeeling(_ mood: ReflectionMood) {
        morningFeeling = mood
        advance()
    }
    
    func selectScheduleConsistency(_ consistency: ReflectionScheduleConsistency) {
        scheduleConsistency = consistency
        Task {
            await saveReflection()
        }
    }
    
    func closeModal() {
        skipForToday()
    }
    
    func resetFlow() {
        currentStep = .sleepQuality
        resetSelections()
        errorMessage = nil
    }
    
    // MARK: - Private Helpers
    private func advance() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            currentStep = next
        }
    }
    
    private func presentIfNeeded(trigger: Trigger) async {
        guard Auth.auth().currentUser?.uid != nil else { return }
        
        let key = Self.dayKey(for: Date())
        let now = Date()
        
        if trigger == .dailyOpen && !isPastPromptTime(now) {
            return
        }
        
        // Already completed today? bail
        if lastCompletedDayKey == key {
            return
        }
        
        // Already prompted today for any trigger? Avoid nagging.
        if lastPromptDayKey == key {
            return
        }
        
        // Avoid duplicate prompts if we already logged a reflection on another device
        if await hasReflectionForToday(dayKey: key) {
            lastCompletedDayKey = key
            return
        }
        
        await MainActor.run {
            resetFlow()
            isPresenting = true
            lastPromptDayKey = key
        }
    }
    
    private func hasReflectionForToday(dayKey: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection(collection)
                .whereField("dayKey", isEqualTo: dayKey)
                .limit(to: 1)
                .getDocuments()
            
            return !snapshot.isEmpty
        } catch {
            print("❌ Failed to check existing reflection: \(error)")
            return false
        }
    }
    
    private func saveReflection() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            closeModal()
            return
        }
        guard let sleepQuality, let morningFeeling, let scheduleConsistency else { return }
        
        isSaving = true
        errorMessage = nil
        
        let key = Self.dayKey(for: Date())
        let reflection = SleepReflection(
            dayKey: key,
            recordedAt: Date(),
            sleepQuality: sleepQuality,
            morningFeeling: morningFeeling,
            scheduleConsistency: scheduleConsistency
        )
        
        do {
            _ = try await service.save(reflection, to: "users/\(uid)/\(collection)")
            lastCompletedDayKey = key
            lastPromptDayKey = key
            withAnimation {
                isPresenting = false
            }
            resetSelections()
        } catch {
            errorMessage = "Couldn't save your reflection right now. Please try again later."
            print("❌ Failed to save reflection: \(error)")
        }
        
        isSaving = false
    }
    
    private func resetSelections() {
        sleepQuality = nil
        morningFeeling = nil
        scheduleConsistency = nil
    }
    
    private func isPastPromptTime(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 4
    }
    
    private static func dayKey(for date: Date) -> String {
        // Treat the "app day" as starting at 4am.
        let calendar = Calendar.current
        let adjusted = calendar.date(byAdding: .hour, value: -4, to: date) ?? date
        let start = calendar.startOfDay(for: adjusted)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }
}
