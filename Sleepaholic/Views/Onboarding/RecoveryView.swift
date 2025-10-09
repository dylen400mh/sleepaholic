//
//  RecoveryView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import SwiftUI

struct RecoverySlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

struct RecoveryView: View {
    @State private var currentIndex: Int = 0
    let slides: [RecoverySlide] = [
        .init(title: "Sleep is a superpower",
              description: "Every night of deep sleep boosts your brain, mood, and recovery by flooding your body with essential hormones."),
        .init(title: "Bad sleep ruins your ambition",
              description: "Poor sleep slowly kills your drive. You’re not tired because you’re lazy—you’re tired because your sleep isn’t doing its job."),
        .init(title: "Lack of sleep shatters your energy",
              description: "Chronic sleep deprivation drains your body, dulls your mind, and leaves you dragging through the day, no matter how much coffee you drink."),
        .init(title: "Feeling stuck?",
              description: "No matter how many hours you sleep, you still wake up groggy, behind, and unmotivated. It’s not just about sleep quantity. It’s about rest that actually restores."),
        .init(title: "Path to recovery",
              description: "Better sleep is possible. By resetting your routine and prioritizing true rest, your body can restore its natural rhythm—leading to sharper focus, more energy, and a better mood throughout the day."),
        .init(title: "Welcome to Sleepaholic",
              description: "Sleepaholic is a class-leading sleep solution built on years of research and real user insights to help you reclaim restful, consistent sleep."),
        .init(title: "Rewire your brain",
              description: "Science-backed sleep habits help retrain your brain, restore natural melatonin and dopamine balance, and reduce the risk of setbacks on your journey to consistent, high-quality rest."),
        .init(title: "Stay consistent",
              description: "Improving sleep takes discipline. Your daily check-ins keep you focused and motivated as you work toward a healthier, more energized version of yourself."),
        .init(title: "Avoid setbacks",
              description: "Sleepaholic learns your sleep patterns and late-night habits to deliver personalized recommendations that help you stay consistent and recover faster."),
        .init(title: "Conquer yourself",
              description: "Know your habits to improve them. Track your progress and build the discipline to take back control of your nights, one sleep at a time."),
        .init(title: "Level up your life",
              description: "Better sleep leads to better everything. Boost your mood, sharpen your mind, and feel stronger.")
    ]
    
    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack {
            // Back button
            BackButtonView(previous: {
                if currentIndex > 0 {
                    withAnimation(.easeInOut) { currentIndex -= 1 }
                } else {
                    previous()
                }
            })
            
            Spacer(minLength: 10)

            // Slide content
            TabView(selection: $currentIndex) {
                ForEach(slides.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        // Placeholder Lottie animation
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay(Text("Lottie").font(.headline))
                            .padding(.top, 30)

                        VStack(spacing: 10) {
                            Text(slides[index].title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text(slides[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .tag(index)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentIndex)

            // Dots indicator
            HStack(spacing: 6) {
                ForEach(slides.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.accentColor : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 16)

            // Next button
            Button {
                HapticsManager.play(.medium)
                if currentIndex < slides.count - 1 {
                    withAnimation(.easeInOut) { currentIndex += 1 }
                } else {
                    HapticsManager.play(.success)
                    next()
                }
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
        .animation(.easeInOut, value: currentIndex)
    }
}

#Preview {
    RecoveryView(next: {}, previous: {})
}
