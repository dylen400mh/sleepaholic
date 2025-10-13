//
//  TestimonialsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-09.
//

import SwiftUI
import StoreKit

struct TestimonialsView: View {
    @Environment(\.requestReview) private var requestReview
    
    let next: () -> Void
    let previous: () -> Void
    
    private let testimonials: [Testimonial] = [
        Testimonial(
            name: "Jenna Morales",
            review: "I didn’t realize how broken my sleep was until I started using Sleepaholic. Two weeks in, I’m falling asleep faster, staying asleep, and actually waking up with energy. It’s like a reset button for my life.",
            imageName: "person.circle.fill"
        ),
        Testimonial(
            name: "Ryan Choi",
            review: "Sleepaholic turned my nights from doomscrolling to peaceful wind-down routines. The streaks, recommendations, and progress tracking keep me motivated without feeling judged. I actually look forward to bedtime now.",
            imageName: "person.circle.fill"
        ),
        Testimonial(
            name: "Emily Robertson",
            review: "Since using Sleepaholic, I finally feel in control of my sleep. The gentle reminders and calming guides help me unplug, and I’ve gone from restless nights to consistent, refreshing sleep. It’s the first time in years I wake up without hitting snooze five times.",
            imageName: "person.circle.fill"
        )
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Back button
            BackButtonView(previous: previous)
                .padding(.top)

            // MARK: - Header
            VStack(spacing: 8) {
                Text("What people say")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("This app was designed for people like you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // MARK: - Testimonials
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(testimonials) { testimonial in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: testimonial.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(testimonial.name)
                                        .font(.headline)
                                    HStack(spacing: 3) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            
                            Text("“\(testimonial.review)”")
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            Spacer(minLength: 20)

            // MARK: - Next button
            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                Text("Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            requestReview()
            AnalyticsService.shared.trackEvent(eventName: "testimonials_viewed")
        }
    }
}

#Preview {
    TestimonialsView(next: {}, previous: {})
}

