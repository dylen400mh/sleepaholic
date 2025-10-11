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
            BackButtonView(previous: previous)

            Spacer()

            Text("Become a Sleepaholic")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
                .frame(height: 50)
                .cornerRadius(8)
                .padding(.horizontal)

                // MARK: - Google Sign-In
                Button(action: {
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
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .imageScale(.medium)
                        Text("Continue with Google")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal)
            }

            Spacer()
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
