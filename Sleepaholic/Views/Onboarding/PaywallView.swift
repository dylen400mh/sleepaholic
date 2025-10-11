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

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    
                    Text("\(userName.isEmpty ? "Y" : userName + ", y")our custom plan is ready.")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Transform your nights and wake up energized, clear-minded, and consistent.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 50)

                // MARK: - Benefits (Part 1)
                VStack(spacing: 16) {
                    ForEach(benefits.prefix(2), id: \.title) { benefit in
                        BenefitCard(benefit: benefit)
                    }
                }
                .padding(.top, 8)

                // MARK: - Testimonial 1
                TestimonialCard(testimonial: testimonials[0])
                    .padding(.horizontal)

                // MARK: - Deeper Benefits
                VStack(spacing: 16) {
                    ForEach(benefits.suffix(2), id: \.title) { benefit in
                        BenefitCard(benefit: benefit)
                    }
                }

                // MARK: - Testimonial 2
                TestimonialCard(testimonial: testimonials[1])
                    .padding(.horizontal)

                // MARK: - Outcome Focus
                VStack(spacing: 8) {
                    Text("Better sleep changes everything.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Sleepaholic helps you rebuild focus, motivation, and energy by fixing the habits that hold your sleep back and replacing them with the ones that work.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // MARK: - Testimonial 3
                TestimonialCard(testimonial: testimonials[2])
                    .padding(.horizontal)

                // MARK: - CTA
                VStack(spacing: 16) {
                    Button {
                        HapticsManager.play(.medium)
                        SuperwallService.shared.presentPaywall(placement: "default")
                        scheduleDiscountNotification()
                    } label: {
                        Text("Unlock My Sleep Plan")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .task {
            await userProfileViewModel.loadProfile()
            if let name = userProfileViewModel.profile?.name {
                userName = name.components(separatedBy: " ").first ?? ""
            }
            await markUserOnboardedOnce()
        }
    }

    // MARK: - Benefits
    private var benefits: [Benefit] {
        [
            Benefit(icon: "sparkles", title: "Sleep Deeper, Wake Sharper", subtitle: "Restore natural sleep cycles and wake up clear-headed every morning."),
            Benefit(icon: "cup.and.saucer.fill", title: "Fix Hidden Sleep Killers", subtitle: "Track caffeine, alcohol, naps, and more to reveal what’s sabotaging your rest."),
            Benefit(icon: "leaf.fill", title: "Rebuild Healthy Habits", subtitle: "Complete nightly wind-downs that calm your mind and train your body to rest."),
            Benefit(icon: "brain.head.profile", title: "Get Personalized Insights", subtitle: "See exactly how your habits impact your sleep and get smarter recommendations every week.")
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
        
        if var profile = userProfileViewModel.profile, profile.onboarded == false {
            profile.onboarded = true
            await userProfileViewModel.saveProfile(profile)
            print("✅ User marked as onboarded (PaywallView)")
        }
    }

    // MARK: - Notification
    private func scheduleDiscountNotification() {
        let content = UNMutableNotificationContent()
        content.title = "\(userName.isEmpty ? "Hey" : userName), we didn’t give up on you."
        content.body = "🎁⏳ Limited-time offer: Get 80% off Sleepaholic Premium and finally fix your sleep for good."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 180, repeats: false)
        let request = UNNotificationRequest(
            identifier: "discount_offer_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Support Views
struct BenefitCard: View {
    let benefit: Benefit
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: benefit.icon)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.accentColor.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.headline)
                Text(benefit.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct TestimonialCard: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            Text("“\(testimonial.review)”")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
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
