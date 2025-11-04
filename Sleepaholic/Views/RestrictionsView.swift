//
//  RestrictionsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-26.
//

import SwiftUI
import FamilyControls

struct RestrictionsView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    
    @State private var showPicker = false
    @State private var requestingAuth = false
    @State private var authError: String?

    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Restrictions")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }

            // MARK: - Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Restrict apps toggle
                    SettingsRow(
                        iconName: "apps",
                        title: "Restrict Apps",
                        hasArrow: false,
                        toggleBinding: Binding(
                            get: { userSettingsViewModel.settings?.restrictApps ?? false },
                            set: { newValue in
                                Task { await handleRestrictAppsToggle(newValue) }
                            }
                        )
                    )

                    SettingsSeparator()

                    // Restricted apps button
                    Button {
                        showPicker = true
                    } label: {
                        HStack(spacing: 16) {
                            Image("apps")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white100)
                            Text("Restricted Apps")
                                .font(.body1Semi)
                                .foregroundColor(.white100)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image("right")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white100)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!(userSettingsViewModel.settings?.restrictApps ?? false))
                    .opacity((userSettingsViewModel.settings?.restrictApps ?? false) ? 1.0 : 0.5)

                    // Summary
                    Text(summaryText)
                        .font(.body2)
                        .foregroundColor(.white70)

                    if let authError {
                        Text(authError)
                            .font(.body3)
                            .foregroundColor(Color.appRed)
                    }
                }
            }
        }
        .padding(.vertical, adaptivePadding)
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .familyActivityPicker(isPresented: $showPicker, selection: $windDown.restrictedApps)
        .appBackground()
    }

    // MARK: - Summary
    private var summaryText: String {
        let a = windDown.restrictedApps.applicationTokens.count
        let c = windDown.restrictedApps.categoryTokens.count
        let w = windDown.restrictedApps.webDomainTokens.count
        return "Selected \(a) apps, \(c) categories, \(w) websites"
    }

    // MARK: - Toggle handling
    private func handleRestrictAppsToggle(_ enabled: Bool) async {
        guard var settings = userSettingsViewModel.settings else { return }
        authError = nil

        if enabled {
            do {
                let status = AuthorizationCenter.shared.authorizationStatus
                if status != .approved {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                }
                settings.restrictApps = true
                await userSettingsViewModel.saveSettings(settings)
            } catch {
                authError = "Screen Time permission was not granted."
                settings.restrictApps = false
                await userSettingsViewModel.saveSettings(settings)
            }
        } else {
            settings.restrictApps = false
            await userSettingsViewModel.saveSettings(settings)
        }
    }
}

#Preview {
    NavigationStack {
        RestrictionsView()
            .environmentObject(WindDownManager())
    }
}

