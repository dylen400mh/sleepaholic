//
//  Testimonial.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-11.
//

import Foundation

struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let review: String
    let imageName: String
}
