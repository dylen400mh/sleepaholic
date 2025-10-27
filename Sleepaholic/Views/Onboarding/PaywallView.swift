//
//  PaywallView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-11.
//

import SwiftUI
import UserNotifications

struct PaywallView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @State private var userName: String = ""
    @State private var hasMarkedOnboarded = false
    
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 48) {
                OnboardingHeader(previous: nil)
                
                VStack(spacing: 12) {
                    Text("\(userName.isEmpty ? "Y" : userName + ", y")our custom plan is ready.")
                        .font(.h2Semi)
                        .foregroundColor(Color.white100)
                        .multilineTextAlignment(.center)
                    
                    Text("Transform your nights and wake up energized, clear-minded, and consistent.")
                        .font(.body2)
                        .foregroundColor(Color.white80)
                        .multilineTextAlignment(.center)
                }
                
                DiscountView()

                VStack(spacing: 32) {
                    ForEach(benefits.prefix(2), id: \.title) { benefit in
                        BenefitCard(benefit: benefit)
                    }
                    
                    
                    PaywallTestimonialCard(testimonial: testimonials[0])
                    
                    
                    ForEach(benefits.suffix(2), id: \.title) { benefit in
                        BenefitCard(benefit: benefit)
                    }
                    
                    PaywallTestimonialCard(testimonial: testimonials[1])
                    
                    VStack(spacing: 12) {
                        Text("Better sleep changes everything.")
                            .font(.h3Semi)
                            .foregroundColor(.white100)
                            .multilineTextAlignment(.center)

                        Text("Sleepaholic helps you rebuild focus, motivation, and energy by fixing the habits that hold your sleep back and replacing them with the ones that work.")
                            .font(.body2)
                            .foregroundColor(.white80)
                            .multilineTextAlignment(.center)
                    }
                    
                    PaywallTestimonialCard(testimonial: testimonials[2])
                }
                
                // MARK: - CTA
                Button {
                    HapticsManager.play(.medium)
                    Task {
                        await pressedButton()
                    }
                } label: {
                    PrimaryButton(
                        title: "Unlock My Sleep Plan",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .task {
            if let name = userProfileViewModel.profile?.name {
                userName = name.components(separatedBy: " ").first ?? ""
            }
            await markUserOnboardedOnce()
        }
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "paywall_viewed")
        }
    }

    // MARK: - Benefits
    private var benefits: [Benefit] {
        [
            Benefit(icon: "charge", title: "Sleep Deeper, Wake Sharper", subtitle: "Restore natural sleep cycles and wake up clear-headed every morning."),
            Benefit(icon: "coffee", title: "Fix Hidden Sleep Killers", subtitle: "Track caffeine, alcohol, naps, and more to reveal what’s sabotaging your rest."),
            Benefit(icon: "book", title: "Rebuild Healthy Habits", subtitle: "Complete nightly wind-downs that calm your mind and train your body to rest."),
            Benefit(icon: "brain", title: "Get Personalized Insights", subtitle: "See exactly how your habits impact your sleep and get smarter recommendations every week.")
        ]
    }

    // MARK: - Testimonials
    private var testimonials: [Testimonial] {
        [
            Testimonial(
                name: "",
                review: "After a week of tracking caffeine and workouts, I finally understood why I wasn’t sleeping. The insights were eye-opening.",
                imageName: ""
            ),
            Testimonial(
                name: "",
                review: "The nightly routine completely changed how I wind down. I fall asleep faster and wake up without that heavy fog.",
                imageName: ""
            ),
            Testimonial(
                name: "",
                review: "Sleepaholic helped me connect my habits to my sleep. Now I actually feel rested when I wake up every day.",
                imageName: ""
            )
        ]
    }

    // MARK: - Onboarded Tracking
    private func markUserOnboardedOnce() async {
        guard !hasMarkedOnboarded else { return }
        hasMarkedOnboarded = true
        
        hasOnboarded = true
        print("✅ User marked as onboarded locally (UserDefaults)")
    }
    
    private func pressedButton() async {
        let userAge = userProfileViewModel.profile?.age ?? 0

        if userAge < 18 {
            SuperwallService.shared.presentPaywall(placement: "under18")
        } else if userAge <= 22 {
            SuperwallService.shared.presentPaywall(placement: "age18to22")
        } else if userAge <= 28 {
            SuperwallService.shared.presentPaywall(placement: "age23to28")
        } else if userAge <= 40 {
            SuperwallService.shared.presentPaywall(placement: "age29to40")
        } else {
            SuperwallService.shared.presentPaywall(placement: "over40")
        }
    }
}

// MARK: - Support Views
struct BenefitCard: View {
    let benefit: Benefit
    
    var body: some View {
        HStack(spacing: 12) {
            Image(benefit.icon)
                .foregroundColor(Color.white100)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.body1Semi)
                    .foregroundColor(Color.white100)
                Text(benefit.subtitle)
                    .font(.body2)
                    .foregroundColor(Color.white80)
            }
            Spacer()
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

struct PaywallTestimonialCard: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.appYellow)
                        .font(.system(size: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            Text("“\(testimonial.review)”")
                .font(.body2)
                .foregroundColor(.white80)
                .multilineTextAlignment(.center)
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

// MARK: - Data Models
struct Benefit {
    let icon: String
    let title: String
    let subtitle: String
}

#Preview {
    PaywallView()
        .environmentObject(UserProfileViewModel())
}
