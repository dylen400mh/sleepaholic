//
//  Color.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-14.
//

import SwiftUI

extension Color {
    // MARK: - Base Colors
    static let main = Color(hex: "#1f1d3f")
    static let main80 = Color(hex: "#1f1d3f").opacity(0.8)
    static let dark = Color(hex: "#131226")
    static let background = Color(hex: "#181534")

    // MARK: - Opacities of White
    static let white100 = Color.white.opacity(1.0)
    static let white80  = Color.white.opacity(0.8)
    static let white70  = Color.white.opacity(0.7)
    static let white50  = Color.white.opacity(0.5)
    static let white40  = Color.white.opacity(0.4)
    static let white20  = Color.white.opacity(0.2)
    static let white10  = Color.white.opacity(0.1)
    static let white5   = Color.white.opacity(0.05)

    // MARK: - Accent Colors
    static let yellow = Color(hex: "#f8c315")
    static let red = Color(hex: "#730303")
    static let green = Color(hex: "#035802")

    static let starsCloudsBackground = Color(hex: "#f7e4fd")
}

// MARK: - Hex Initializer
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF,
                            int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

