//
//  RecoveryView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import SwiftUI
import DotLottie

struct RecoverySlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let image: String
}

struct RecoveryView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @State private var currentIndex: Int = 0
    let slides: [RecoverySlide] = [
        .init(title: "Sleep is a superpower",
              description: "Every night of deep sleep boosts your brain, mood, and recovery by flooding your body with essential hormones.",
              image: "Sleep more"),
        .init(title: "Bad sleep ruins your ambition",
              description: "Poor sleep slowly kills your drive. You’re not tired because you’re lazy—you’re tired because your sleep isn’t doing its job.",
              image: "Emoji Bad"),
        .init(title: "Lack of sleep shatters your energy",
              description: "Chronic sleep deprivation drains your body, dulls your mind, and leaves you dragging through the day, no matter how much coffee you drink.",
              image:"Tired Woman"),
        .init(title: "Feeling stuck?",
              description: "No matter how many hours you sleep, you still wake up groggy, behind, and unmotivated. It’s not just about sleep quantity. It’s about rest that actually restores.",
              image:"Sleeping Cat"),
        .init(title: "Path to recovery",
              description: "Better sleep is possible. By resetting your routine and prioritizing true rest, your body can restore its natural rhythm—leading to sharper focus, more energy, and a better mood throughout the day.",
              image:"Relax"),
        .init(title: "Welcome to Sleepaholic",
              description: "Sleepaholic is a class-leading sleep solution built on years of research and real user insights to help you reclaim restful, consistent sleep.",
              image:"Sleeping"),
        .init(title: "Rewire your brain",
              description: "Science-backed sleep habits help retrain your brain, restore natural melatonin and dopamine balance, and reduce the risk of setbacks on your journey to consistent, high-quality rest.",
              image:"Brain AI"),
        .init(title: "Stay consistent",
              description: "Improving sleep takes discipline. Your daily check-ins keep you focused and motivated as you work toward a healthier, more energized version of yourself.",
              image:"Check In"),
        .init(title: "Avoid setbacks",
              description: "Sleepaholic learns your sleep patterns and late-night habits to deliver personalized recommendations that help you stay consistent and recover faster.",
              image:"success"),
        .init(title: "Conquer yourself",
              description: "Know your habits to improve them. Track your progress and build the discipline to take back control of your nights, one sleep at a time.",
              image:"graph"),
        .init(title: "Level up your life",
              description: "Better sleep leads to better everything. Boost your mood, sharpen your mind, and feel stronger.",
              image:"Success (1)")
    ]
    
    let next: () -> Void
    let previous: () -> Void
    let startIndex: Int

    var body: some View {
        VStack {
            VStack(spacing: 48) {
                header
                
                VStack(spacing: 24) {
                    TabView(selection: $currentIndex) {
                        ForEach(slides.indices, id: \.self) { index in
                            VStack(spacing: 24) {
                                card(for: slides[index])
                                Spacer()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentIndex)
                    
                    indicators
                    
                    Spacer()
                }
            }
            
            footer
        }
        .padding(.horizontal, 24)
        .padding(.bottom, adaptivePadding)
        .onAppear {
            currentIndex = startIndex
            AnalyticsService.shared.trackEvent(eventName: "recovery_viewed")
        }
        .onChange(of: currentIndex) { oldIndex, newIndex in
            AnalyticsService.shared.trackEvent(eventName: "recovery_slide_\(newIndex + 1)_viewed")
        }
        .animation(.easeInOut, value: currentIndex)
    }
}

// MARK: - Subviews
private extension RecoveryView {
    var header: some View {
        OnboardingHeader(previous: {
            if currentIndex > 0 {
                withAnimation(.easeInOut) { currentIndex -= 1 }
            } else {
                previous()
            }
        })
    }

    func card(for slide: RecoverySlide) -> some View {
        VStack(spacing: 24) {
            if slides[currentIndex].id == slide.id {
                DotLottieAnimation(fileName: slide.image, config: AnimationConfig(autoplay: true, loop: true))
                    .view()
                    .frame(width: 200, height: 200)
                    .clipped()
            } else { // placeholder so we don't load all animations at once
                Rectangle()
                    .opacity(0)
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)
            }
            
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                    .multilineTextAlignment(.center)
                
                Text(slide.description)
                    .font(.body2)
                    .foregroundColor(.white80)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color.white5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white10, lineWidth: 1)
        )
        .cornerRadius(24)
    }

    var indicators: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { index in
                Circle()
                    .fill(Color.white20)
                    .overlay {
                        if index == currentIndex {
                            Circle().fill(Gradients.main)
                        }
                    }
                    .frame(width: 12, height: 12)
                    .cornerRadius(100)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            currentIndex = index
                        }
                    }
            }
        }
    }

    var footer: some View {
        HStack(spacing: 28) {
            Button {
                HapticsManager.play(.light)
                next()
            } label: {
                Text("Skip all")
                    .font(.body1Semi)
                    .foregroundColor(.white100)
            }

            Button {
                HapticsManager.play(.medium)
                if currentIndex < slides.count - 1 {
                    withAnimation(.easeInOut) { currentIndex += 1 }
                } else {
                    HapticsManager.play(.success)
                    next()
                }
            } label: {
                SecondaryButton(
                    title: "Next",
                    icon: Image(systemName: "arrow.right"),
                    size: .small,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    RecoveryView(next: {}, previous: {}, startIndex: 0)
}
