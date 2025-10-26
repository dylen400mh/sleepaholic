//
//  MoreView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-26.
//

import SwiftUI
import StoreKit

struct MoreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("More")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }

            // MARK: - Options
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Rate Sleepaholic
                    Button {
                        requestAppReview()
                    } label: {
                        SettingsRow(iconName: nil, title: "Rate Sleepaholic")
                    }
                    .buttonStyle(.plain)
                    SettingsSeparator()

                    // Suggest a Change or Feature
                    Button {
                        openSuggestionEmail()
                    } label: {
                        SettingsRow(iconName: nil, title: "Suggest a Change or Feature")
                    }
                    .buttonStyle(.plain)
                    SettingsSeparator()

                    // Terms of Use
                    Button {
                        openURL(URL(string: "https://sleepaholicapp.com/terms")!)
                    } label: {
                        SettingsRow(iconName: nil, title: "Terms of Use")
                    }
                    .buttonStyle(.plain)
                    SettingsSeparator()

                    // Privacy Policy
                    Button {
                        openURL(URL(string: "https://sleepaholicapp.com/privacy")!)
                    } label: {
                        SettingsRow(iconName: nil, title: "Privacy Policy")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .appBackground()
    }

    // MARK: - Email Template
    private func openSuggestionEmail() {
        let subject = "Feature Suggestion for Sleepaholic"
        let body = """

        [Describe your suggestion here]

        """
        let email = "support@sleepaholicapp.com"

        let mailtoURL = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: mailtoURL) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - App Review
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

#Preview {
    NavigationStack {
        MoreView()
    }
}
