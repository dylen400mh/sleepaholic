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
        }
        .padding(.horizontal, 24)
        .padding(.vertical, adaptivePadding)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
    }
}

private struct CustomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 16) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    if tab == .sleep {
                        SleepTabButton(isSelected: selection == .sleep)
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selection == tab ? .white100 : .white70)
                            Text(tab.title)
                                .font(.system(size: tab == .windDown ? 10 : 12, weight: .semibold))
                                .foregroundColor(selection == tab ? .white100 : .white70)
                                .lineLimit(tab == .windDown ? 2 : 1)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle()) 
                    }
                }
                .buttonStyle(.plain)
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
}

private struct SleepTabButton: View {
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: AppTab.sleep.iconName)
                .font(.system(size: 18, weight: .semibold))
            Text(AppTab.sleep.title)
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
                        .stroke(Color.white40, lineWidth: 1)
                )
        )
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
