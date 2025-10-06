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
    @StateObject private var authService = AuthService.shared
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Become a Sleepaholic")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // MARK: - Apple Sign-In
                SignInWithAppleButton(.signIn) { request in
                    authService.signInWithApple(request: request)
                } onCompletion: { result in
                    Task {
                        do {
                            try await authService.handleAppleSignIn(result: result)
                            if let user = Auth.auth().currentUser {
                                let newProfile = UserProfile(
                                    name: user.displayName ?? "",
                                    age: 0,
                                    gender: "",
                                    createdAt: Date()
                                )
                                await userProfileViewModel.saveProfile(newProfile)
                            }
                            next()
                        } catch {
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
                    Task {
                        do {
                            try await authService.signInWithGoogle()
                            if let user = Auth.auth().currentUser {
                                let newProfile = UserProfile(
                                    name: user.displayName ?? "",
                                    age: 0,
                                    gender: "",
                                    createdAt: Date()
                                )
                                await userProfileViewModel.saveProfile(newProfile)
                            }
                            next()
                        } catch {
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

                // MARK: - Skip
                Button("Skip for now") {
                    next()
                }
                .foregroundColor(.gray)
                .padding(.top, 4)
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
    AuthView(next: {})
}
