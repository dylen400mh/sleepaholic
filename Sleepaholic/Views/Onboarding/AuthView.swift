//
//  AuthView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel

    let next: () -> Void
    let previous: () -> Void
    @StateObject private var authService = AuthService.shared
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(previous: previous)

            Spacer()

            Text("Become a Sleepaholic")
                .font(.h1Black)
                .foregroundColor(Color.white100)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()

            VStack(spacing: 16) {
                // MARK: - Apple Sign-In
                SignInWithAppleButton(.signIn) { request in
                    HapticsManager.play(.light)
                    authService.signInWithApple(request: request)
                } onCompletion: { result in
                    Task {
                        do {
                            try await authService.handleAppleSignIn(result: result)
                            HapticsManager.play(.success)
                            next()
                        } catch {
                            HapticsManager.play(.error)
                            showError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .frame(width: 342, height: 56)
                .cornerRadius(100)
                .buttonStyle(.plain)

                // MARK: - Google Sign-In
                PrimaryButton(
                    title: "Continue with Google",
                    icon: Image("google"),
                    size: .regular,
                    isDisabled: false
                ) {
                    HapticsManager.play(.medium)
                    Task {
                        do {
                            try await authService.signInWithGoogle()
                            HapticsManager.play(.success)
                            next()
                        } catch {
                            HapticsManager.play(.error)
                            showError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "auth_viewed")
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    AuthView(next: {}, previous: {})
}
