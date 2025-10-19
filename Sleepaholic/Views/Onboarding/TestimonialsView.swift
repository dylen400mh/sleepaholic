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
            imageName: "testimonial1"
        ),
        Testimonial(
            name: "Ryan Choi",
            review: "Sleepaholic turned my nights from doomscrolling to peaceful wind-down routines. The streaks, recommendations, and progress tracking keep me motivated without feeling judged. I actually look forward to bedtime now.",
            imageName: "testimonial2"
        ),
        Testimonial(
            name: "Emily Robertson",
            review: "Since using Sleepaholic, I finally feel in control of my sleep. The gentle reminders and calming guides help me unplug, and I’ve gone from restless nights to consistent, refreshing sleep. It’s the first time in years I wake up without hitting snooze five times.",
            imageName: "testimonial3"
        )
    ]
    
    var body: some View {
        VStack(spacing: 48) {
            OnboardingHeader(previous: previous)
            
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("What people say")
                        .font(.h2Semi)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("This app was designed for people like you.")
                        .font(.body2)
                        .foregroundColor(.white80)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        ForEach(testimonials) { testimonial in
                            TestimonialCard(
                                name: testimonial.name,
                                profileImage: Image(testimonial.imageName),
                                review: testimonial.review,
                                showCheckmark: false,
                                showStars: true
                            )
                        }
                    }
                }
            }

            // MARK: - Next button
            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                PrimaryButton(
                   title: "Next",
                   icon: nil,
                   size: .regular,
                   isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
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

