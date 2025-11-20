//
//  MainTabView.swift
//  Sleepaholic
//
//  Created by John on 2025-11-08.
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case insights
    case activities
    case sleep
    case windDown
    case settings

    var title: String {
        switch self {
        case .insights: return "Insights"
        case .activities: return "Activities"
        case .sleep: return "Sleep"
        case .windDown: return "Wind Down"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .insights: return "waveform.path.ecg"
        case .activities: return "figure.walk"
        case .sleep: return "moon.stars.fill"
        case .windDown: return "sparkles"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct MainTabView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding
    @EnvironmentObject private var guidedTourManager: GuidedTourManager
    @EnvironmentObject private var userSettingsViewModel: UserSettingsViewModel
    
    @State private var selection: AppTab = .sleep

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selection {
                case .insights:
                    InsightsView()
                case .activities:
                    ActivitiesView()
                case .sleep:
                    ContentView()
                case .windDown:
                    WindDownView()
                case .settings:
                    SettingsView(showsBackButton: false)
                }
            }

            CustomTabBar(selection: $selection)
                .guidedTourTarget(.tabBar)
        }
        .padding(.horizontal, 24)
        .padding(.top, adaptivePadding + 8)
        .padding(.bottom, adaptivePadding)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .overlayPreferenceValue(GuidedTourTargetPreferenceKey.self) { targets in
            GeometryReader { proxy in
                GuidedTourOverlay(manager: guidedTourManager, proxy: proxy, targets: targets)
                    .opacity(guidedTourManager.isPresenting ? 1 : 0)
                    .animation(.easeInOut, value: guidedTourManager.isPresenting)
            }
            .allowsHitTesting(guidedTourManager.isPresenting)
            .zIndex(10)
        }
        .onAppear {
            guidedTourManager.evaluateAutoShowEligibility(
                hasCompleted: userSettingsViewModel.settings?.hasCompletedGuidedTour ?? false
            )
        }
        .onChange(of: userSettingsViewModel.settings?.hasCompletedGuidedTour ?? false) { _, newValue in
            guidedTourManager.evaluateAutoShowEligibility(hasCompleted: newValue)
        }
        .onChange(of: guidedTourManager.currentStepIndex) { _, _ in
            guard let step = guidedTourManager.currentStep else { return }
            if selection != step.associatedTab {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                    selection = step.associatedTab
                }
            }
        }
        .onChange(of: guidedTourManager.lastCompletion) { _, completion in
            guard completion != nil else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                selection = .sleep
            }
            Task {
                await userSettingsViewModel.markGuidedTourCompletedIfNeeded()
            }
        }
    }
}

private struct CustomTabBar: View {
    @Binding var selection: AppTab
    @EnvironmentObject private var guidedTourManager: GuidedTourManager

    var body: some View {
        HStack(spacing: 16) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    TabButtonView(
                        tab: tab,
                        isSelected: selection == tab,
                        isEmphasized: shouldEmphasize(tab),
                        isDimmed: shouldDim(tab)
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .guidedTourTarget(.tab(tab))
            }
        }
        .padding(.top, 8)
        .background(
            LinearGradient(
                colors: [Color.background.opacity(0.95), Color.background.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var isTourActive: Bool {
        guidedTourManager.isPresenting
    }
    
    private func shouldEmphasize(_ tab: AppTab) -> Bool {
        guard isTourActive else { return false }
        if guidedTourManager.showingTabIntro {
            return false
        }
        return guidedTourManager.currentStep?.associatedTab == tab
    }
    
    private func shouldDim(_ tab: AppTab) -> Bool {
        if guidedTourManager.showingTabIntro { return false }
        return isTourActive && !shouldEmphasize(tab)
    }
}

private struct TabButtonView: View {
    let tab: AppTab
    let isSelected: Bool
    let isEmphasized: Bool
    let isDimmed: Bool

    var body: some View {
        Group {
            if tab == .sleep {
                VStack(spacing: 4) {
                    Image(systemName: tab.iconName)
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.title)
                        .font(.body2Semi)
                }
                .foregroundColor(.white100)
                .frame(width: 92, height: 56)
                .background(
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.gradientStart, Color.gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .shadow(color: Color.main.opacity(0.45), radius: 18, x: 0, y: 10)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(isEmphasized ? Color.white100 : Color.white40, lineWidth: isEmphasized ? 2 : 1)
                        )
                )
            } else {
                VStack(spacing: 6) {
                    Image(systemName: tab.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tabForegroundColor)
                    Text(tab.title)
                        .font(.system(size: tab == .windDown ? 10 : 12, weight: .semibold))
                        .foregroundColor(tabForegroundColor)
                        .lineLimit(tab == .windDown ? 2 : 1)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .opacity(isDimmed ? 0.2 : 1)
    }
    
    private var tabForegroundColor: Color {
        if isDimmed { return .white40 }
        return isSelected ? .white100 : .white70
    }
}

#Preview {
    MainTabView()
        .environmentObject(WindDownManager())
        .environmentObject(UserSettingsViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(SleepLogViewModel())
        .environmentObject(UserProfileViewModel())
        .environmentObject(SleepClipViewModel())
        .enableAdaptivePadding()
}
