//
//  Date.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-16.
//

import Foundation

extension Date {
    func formattedTimeHMS() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
}
