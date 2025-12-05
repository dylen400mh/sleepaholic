//
//  ShieldConfigurationExtension.swift
//  SleepaholicShield
//
//  Created by Dylen Belanger on 2025-12-04.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func customShield(title: String) -> ShieldConfiguration {

        let bgColor = UIColor(red: 0x18/255.0, green: 0x15/255.0, blue: 0x34/255.0, alpha: 1.0)

        let icon = UIImage(named: "AppIcon")

        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: bgColor,
            icon: icon,
            title: ShieldConfiguration.Label(
                text: title,
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: """
                It's time to wind down and get ready for sleep.
                If needed, you can adjust your Wind-Down settings inside Sleepaholic.
                """,
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }

    // 🔒 App directly restricted
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return customShield(title: "🔒 \(application.localizedDisplayName ?? "This app") is blocked by Sleepaholic")
    }

    // 🔒 App restricted because of its category
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return customShield(title: "🔒 \(application.localizedDisplayName ?? "This app") is blocked by Sleepaholic")
    }

    // 🌐 Website directly restricted
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return customShield(title: "🔒 This website is blocked by Sleepaholic")
    }

    // 🌐 Website restricted due to category
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return customShield(title: "🔒 This website is blocked by Sleepaholic")
    }
}
