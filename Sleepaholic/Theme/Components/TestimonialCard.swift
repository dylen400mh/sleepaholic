//
//  TestimonialCard.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct TestimonialCard: View {
    let name: String
    let profileImage: Image
    let review: String
    let showCheckmark: Bool
    let showStars: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - Header
            HStack(alignment: .center, spacing: 12) {
                // Profile image
                profileImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                
                // Name
                Text(name)
                    .font(.body2Semi)
                    .foregroundColor(.white100)
                
                Spacer()
                
                // Checkmark (optional)
                if showCheckmark {
                    Image(systemName: "checkmark.seal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white100)
                }
            }
            
            // MARK: - Stars (optional)
            if showStars {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color.appYellow)
                    }
                }
            }
            
            // MARK: - Review text
            Text(review)
                .font(.body2)
                .foregroundColor(.white80)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.main)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white5, lineWidth: 1)
        )
    }
}

