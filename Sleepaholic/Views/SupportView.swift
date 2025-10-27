//
//  SupportView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-26.
//

import SwiftUI
import UIKit

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMailAlert = false

    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Support")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }

            // MARK: - List
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Report a bug
                    Button {
                        openEmail(subject: "Sleepaholic Bug Report", template: bugTemplate)
                    } label: {
                        SettingsRow(iconName: nil, title: "Report a Bug", hasArrow: true)
                    }
                    SettingsSeparator()

                    // FAQs
                    Button {
                        openFAQ()
                    } label: {
                        SettingsRow(iconName: nil, title: "FAQs", hasArrow: true)
                    }
                    SettingsSeparator()

                    // Contact us
                    Button {
                        openEmail(subject: "Sleepaholic Support Inquiry", template: contactTemplate)
                    } label: {
                        SettingsRow(iconName: nil, title: "Contact Us", hasArrow: true)
                    }
                }
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .appBackground()
        .alert("Mail not configured", isPresented: $showMailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You don’t have a mail account set up on this device.")
        }
    }

    // MARK: - Email Helpers
    private func openEmail(subject: String, template: String) {
        let email = "support@sleepaholicapp.com"
        let body = template.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(body)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailAlert = true
        }
    }

    // MARK: - Templates
    private var bugTemplate: String {
        """
        Description of the issue:
        Steps to reproduce:
        Expected behavior:
        Actual behavior:
        Device model:
        iOS version:
        App version:
        """
    }

    private var contactTemplate: String {
        """
        """
    }

    // MARK: - Open FAQ
    private func openFAQ() {
        if let url = URL(string: "https://sleepaholicapp.com/faq") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}


