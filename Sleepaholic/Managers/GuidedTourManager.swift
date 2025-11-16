//
//  GuidedTourManager.swift
//  Sleepaholic
//
//  Created by John on 2025-11-16.
//

import SwiftUI

enum GuidedTourTarget: Hashable {
    case sleepInsights
    case startBedtime
    case activitiesLog
    case insightsDeepDive
    case windDownRestrictions
    case tabBar
    case tab(AppTab)
}

enum GuidedTourTriggerReason: String {
    case none
    case postPaywall
    case settingsReplay
}

struct GuidedTourStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let highlightTarget: GuidedTourTarget?
    let associatedTab: AppTab
    
    static let defaultSteps: [GuidedTourStep] = [
        GuidedTourStep(
            title: "Insights Tab",
            message: "See how your sleep score, duration, and clips evolve over time so you can spot trends that matter.",
            highlightTarget: nil,
            associatedTab: .insights
        ),
        GuidedTourStep(
            title: "Activities Tab",
            message: "Quickly log caffeine, workouts, naps, and more so Sleepaholic can connect your habits to tonight’s sleep.",
            highlightTarget: nil,
            associatedTab: .activities
        ),
        GuidedTourStep(
            title: "Sleep Tab",
            message: "Your nightly home base for sleep debt, AI insights, and kicking off your bedtime flow.",
            highlightTarget: nil,
            associatedTab: .sleep
        ),
        GuidedTourStep(
            title: "Wind Down Tab",
            message: "Schedule wind-down, choose sounds or meditations, and restrict apps to avoid doomscrolling.",
            highlightTarget: nil,
            associatedTab: .windDown
        ),
        GuidedTourStep(
            title: "Settings Tab",
            message: "Manage your profile, schedule, restrictions, and access support or more tools anytime.",
            highlightTarget: nil,
            associatedTab: .settings
        )
    ]
}

final class GuidedTourManager: ObservableObject {
    static let shared = GuidedTourManager()
    
    @Published private(set) var currentStepIndex: Int?
    @Published private(set) var isPresenting = false
    @Published private(set) var showingWelcome = false
    @Published private(set) var showingTabIntro = false
    @Published private(set) var lastCompletion: GuidedTourCompletion?
    
    let steps: [GuidedTourStep]
    
    private let pendingReasonKey = "com.sleepaholic.guidedTour.pendingReason"
    private(set) var pendingReason: GuidedTourTriggerReason
    private(set) var currentReason: GuidedTourTriggerReason = .none
    
    private init() {
        self.steps = GuidedTourStep.defaultSteps
        if let stored = UserDefaults.standard.string(forKey: pendingReasonKey) {
            self.pendingReason = GuidedTourTriggerReason(rawValue: stored) ?? .none
        } else {
            self.pendingReason = .none
        }
    }
    
    var currentStep: GuidedTourStep? {
        guard let index = currentStepIndex, steps.indices.contains(index) else {
            return nil
        }
        return steps[index]
    }
    
    func schedulePostPaywallTour() {
        pendingReason = .postPaywall
        persistPendingReason()
    }
    
    func requestReplayFromSettings() {
        start(reason: .settingsReplay)
    }
    
    func evaluateAutoShowEligibility(hasCompleted: Bool) {
        guard !isPresenting else { return }
        guard pendingReason != .none else { return }
        
        if pendingReason == .postPaywall, hasCompleted {
            clearPendingReason()
            return
        }
        
        start(reason: pendingReason)
    }
    
    func advance() {
        guard let index = currentStepIndex else { return }
        if index + 1 < steps.count {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentStepIndex = index + 1
            }
        } else {
            finish(cancelled: false)
        }
    }
    
    func skip() {
        finish(cancelled: true)
    }
    
    private func start(reason: GuidedTourTriggerReason) {
        guard !steps.isEmpty else { return }
        guard !isPresenting else { return }
        clearPendingReason()
        currentReason = reason
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isPresenting = true
            showingWelcome = true
            showingTabIntro = false
        }
    }
    
    func advancePastWelcome() {
        guard showingWelcome else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showingWelcome = false
            showingTabIntro = true
        }
    }
    
    func advancePastTabIntro() {
        guard showingTabIntro else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showingTabIntro = false
            currentStepIndex = 0
        }
    }
    
    private func finish(cancelled: Bool) {
        let completion = GuidedTourCompletion(cancelled: cancelled, trigger: currentReason)
        currentReason = .none
        withAnimation(.easeOut(duration: 0.2)) {
            currentStepIndex = nil
            isPresenting = false
            showingWelcome = false
            showingTabIntro = false
        }
        lastCompletion = completion
    }
    
    private func clearPendingReason() {
        pendingReason = .none
        persistPendingReason()
    }
    
    private func persistPendingReason() {
        if pendingReason == .none {
            UserDefaults.standard.removeObject(forKey: pendingReasonKey)
        } else {
            UserDefaults.standard.set(pendingReason.rawValue, forKey: pendingReasonKey)
        }
    }
}

struct GuidedTourCompletion: Equatable {
    let id = UUID()
    let cancelled: Bool
    let trigger: GuidedTourTriggerReason
}

// MARK: - Geometry Capture

struct GuidedTourTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [GuidedTourTarget: Anchor<CGRect>] = [:]
    
    static func reduce(value: inout [GuidedTourTarget: Anchor<CGRect>],
                       nextValue: () -> [GuidedTourTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct GuidedTourTargetModifier: ViewModifier {
    let target: GuidedTourTarget
    
    func body(content: Content) -> some View {
        content.anchorPreference(key: GuidedTourTargetPreferenceKey.self, value: .bounds) {
            [target: $0]
        }
    }
}

extension View {
    func guidedTourTarget(_ target: GuidedTourTarget) -> some View {
        modifier(GuidedTourTargetModifier(target: target))
    }
}

// MARK: - Overlay

struct GuidedTourOverlay: View {
    @ObservedObject var manager: GuidedTourManager
    
    let proxy: GeometryProxy
    let targets: [GuidedTourTarget: Anchor<CGRect>]
    
    var body: some View {
        if manager.showingWelcome {
            GuidedTourWelcomeView {
                manager.advancePastWelcome()
            }
            .transition(.opacity.combined(with: .scale))
            .ignoresSafeArea()
        } else if manager.showingTabIntro {
            let rect = frame(for: .tabBar).map { tabRect in
                CGRect(
                    x: -16,
                    y: tabRect.minY + 20,
                    width: proxy.size.width + 32,
                    height: tabRect.height + 12
                )
            }
            GuidedTourInstructionView(
                title: "Navigate Your Journey",
                message: "Use these tabs to hop between your insights, activity logs, sleep, nightly wind down, and settings.",
                mainHighlight: rect,
                tabHighlight: nil,
                tabBarRect: frame(for: .tabBar),
                dimTabBar: false,
                progressText: nil,
                forceCenterText: true,
                showsSkip: true,
                proxy: proxy,
                skipAction: { manager.skip() },
                tapAction: { manager.advancePastTabIntro() }
            )
            .transition(.opacity)
        } else if let step = manager.currentStep {
            let tabBarRect = frame(for: .tabBar).map { tabRect in
                CGRect(
                    x: -16,
                    y: tabRect.minY + 20,
                    width: proxy.size.width + 32,
                    height: tabRect.height + 12
                )
            }
            let tabRect = frame(for: .tab(step.associatedTab))
            
            GuidedTourInstructionView(
                title: step.title,
                message: step.message,
                mainHighlight: nil,
                tabHighlight: tabRect,
                tabBarRect: tabBarRect,
                dimTabBar: true,
                progressText: progressText,
                forceCenterText: true,
                showsSkip: true,
                proxy: proxy,
                skipAction: { manager.skip() },
                tapAction: { manager.advance() }
            )
            .transition(.opacity)
        }
    }
    
    private var progressText: String {
        guard let index = manager.currentStepIndex else { return "" }
        return "\(index + 1) of \(manager.steps.count)"
    }
    
private func frame(for target: GuidedTourTarget?) -> CGRect? {
        guard let target, let anchor = targets[target] else { return nil }
        return proxy[anchor]
    }
    
}

private struct GuidedTourWelcomeView: View {
    let tapAction: () -> Void
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.background.opacity(0.95), Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("Welcome to Sleepaholic")
                    .font(.h2Semi)
                    .foregroundStyle(Gradients.main)
                    .multilineTextAlignment(.center)
                
                Text("You just took the first step toward better nights and brighter mornings. We’re thrilled to guide you.")
                    .font(.body1)
                    .foregroundColor(.white80)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Image("profile_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(36)
                    .background(
                        Circle()
                            .fill(Color.white10)
                            .shadow(color: Color.main.opacity(0.45), radius: 35, x: 0, y: 25)
                    )
                    .offset(y: bounce ? -12 : 12)
                    .scaleEffect(bounce ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: bounce
                    )
                
                Text("Tap anywhere to begin")
                    .font(.body2Semi)
                    .foregroundStyle(Gradients.main)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            bounce = true
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction()
        }
    }
}

private struct GuidedTourInstructionView: View {
    let title: String
    let message: String
    let mainHighlight: CGRect?
    let tabHighlight: CGRect?
    let tabBarRect: CGRect?
    let dimTabBar: Bool
    let progressText: String?
    let forceCenterText: Bool
    let showsSkip: Bool
    let proxy: GeometryProxy
    let skipAction: () -> Void
    let tapAction: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            multiHighlightLayer()
            
            if let tabRect = adjustedTabHighlight {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Gradients.main.opacity(0.25))
                    .frame(width: tabRect.width + 18, height: tabRect.height + 18)
                    .position(x: tabRect.midX, y: tabRect.midY)
                    .blur(radius: 8)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
            
            header
            
            textBlock
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction()
        }
    }
    
    private var header: some View {
        HStack {
            if let progressText {
                Text(progressText)
                    .font(.body1Semi)
                    .foregroundColor(.white80)
            }
            Spacer()
            if showsSkip {
                Button("Skip Tour") {
                    skipAction()
                }
                .font(.body1Semi)
                .foregroundColor(.white80)
                .underline()
                .buttonStyle(.plain)
            }
        }
        .padding(.top, proxy.safeAreaInsets.top + 28)
        .padding(.horizontal, 40)
    }
    
    private var textBlock: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.h2Semi)
                .foregroundStyle(Gradients.main)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body1)
                .foregroundColor(.white80)
                .multilineTextAlignment(.center)
            Text("Tap anywhere to continue")
                .font(.body2Semi)
                .foregroundStyle(Gradients.main)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .position(x: proxy.size.width / 2, y: textYPosition())
    }
    
    private func textYPosition() -> CGFloat {
        let topBound = proxy.safeAreaInsets.top + 80
        let bottomBound = proxy.size.height - proxy.safeAreaInsets.bottom - 80
        
        if forceCenterText {
            return proxy.size.height / 2
        }
        
        guard let reference = tabBarRect ?? mainHighlight ?? tabHighlight else {
            return proxy.size.height / 2
        }
        
        let height = proxy.size.height
        if reference.midY < height * 0.35 {
            return min(reference.maxY + 140, bottomBound)
        } else if reference.midY > height * 0.65 {
            return max(reference.minY - 140, topBound)
        } else {
            return proxy.size.height / 2
        }
    }
    
    @ViewBuilder
    private func multiHighlightLayer() -> some View {
        let highlightTargets = highlightRects()
        let background = Color.black.opacity(0.82)
            .mask(
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        ZStack {
                            ForEach(Array(highlightTargets.enumerated()), id: \.offset) { _, rect in
                                RoundedRectangle(cornerRadius: 24)
                                    .frame(width: rect.width + 24, height: rect.height + 24)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            }
                            if dimTabBar, let tabBarRect = adjustedTabBarRect {
                                RoundedRectangle(cornerRadius: 0)
                                    .frame(width: tabBarRect.width + 24, height: tabBarRect.height + 8)
                                    .position(x: tabBarRect.midX, y: tabBarRect.midY)
                                    .blendMode(.destinationOut)
                            }
                        }
                    )
                    .compositingGroup()
            )
        
        background
            .ignoresSafeArea()
            .overlay(
                ZStack {
                    ForEach(Array(highlightTargets.enumerated()), id: \.offset) { _, rect in
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Gradients.main, lineWidth: 2)
                            .blur(radius: 6)
                            .frame(width: rect.width + 24, height: rect.height + 24)
                            .position(x: rect.midX, y: rect.midY)
                    }
                    if dimTabBar, let tabBarRect = adjustedTabBarRect {
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Gradients.main.opacity(0.6), lineWidth: 1.5)
                            .blur(radius: 6)
                            .frame(width: tabBarRect.width + 24, height: tabBarRect.height + 8)
                            .position(x: tabBarRect.midX, y: tabBarRect.midY)
                    }
                    if let tabRect = adjustedTabHighlight {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Gradients.main.opacity(0.25))
                            .frame(width: tabRect.width + 20, height: tabRect.height + 20)
                            .position(x: tabRect.midX, y: tabRect.midY)
                            .blur(radius: 4)
                    }
                }
            )
            .allowsHitTesting(false)
    }
    
    private func highlightRects() -> [CGRect] {
        var rects: [CGRect] = []
        
        if var rect = mainHighlight {
            if let tab = adjustedTabHighlight {
                // If main highlight overlaps tab highlight (e.g., tab intro), avoid double circles
                let distance = abs(rect.midY - tab.midY)
                if distance < (rect.height + tab.height) / 2 {
                    // treat as single merged rect
                    rect = rect.union(tab)
                    return [rect]
                }
            }
            rects.append(rect)
        }
        
        if let tab = adjustedTabHighlight {
            rects.append(tab)
        }
        
        return rects
    }
}

private extension GuidedTourInstructionView {
    var adjustedTabHighlight: CGRect? {
        tabHighlight?.insetBy(dx: -6, dy: -4)
    }
    
    var adjustedTabBarRect: CGRect? {
        tabBarRect?.insetBy(dx: -6, dy: -4)
    }
}
