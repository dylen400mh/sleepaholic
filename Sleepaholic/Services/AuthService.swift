//
//  AuthService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User? = Auth.auth().currentUser
    private var currentNonce: String?
    private var authListenerHandle: AuthStateDidChangeListenerHandle?

    override private init() {
        super.init()
        authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            Task {
                if let user = user {
                    print("👤 Auth state changed: \(user.uid)")

                    // Identify for analytics
                    AnalyticsService.shared.identify(
                        name: user.displayName,
                        userId: user.uid,
                        email: user.email ?? ""
                    )

                    // Ensure Firestore profile exists before exposing user to UI
                    let service = FirestoreService.shared
                    let collection = "users"
                    let existingProfile: UserProfile? = try? await service.fetch(from: collection, id: user.uid)
                    
                    if existingProfile == nil {
                        let profile = UserProfile(
                            name: user.displayName ?? "",
                            age: 0,
                            gender: "",
                            createdAt: Date()
                        )
                        try? await service.save(profile, to: collection, id: user.uid)
                        print("🆕 Created Firestore profile for \(user.uid)")
                    } else {
                        print("ℹ️ Existing profile found for \(user.uid)")
                    }
                    
                    // refresh reviewer status so reviewer can bypass paywall
                    await SuperwallService.shared.refreshReviewerStatus()

                    // Now update published state after everything is ready
                    await MainActor.run {
                        self.currentUser = user
                    }
                } else {
                    await MainActor.run {
                        self.currentUser = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In
    func signInWithApple(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw URLError(.cannotParseResponse)
            }

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            try await Auth.auth().signIn(with: credential)
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Google Sign-In (Firebase Native OAuth)
    func signInWithGoogle() async throws {
        let provider = OAuthProvider(providerID: "google.com")
        
        provider.customParameters = [
            "prompt": "select_account"
        ]
        
        let credential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthCredential, Error>) in
            provider.getCredentialWith(nil) { credential, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let credential = credential {
                    continuation.resume(returning: credential)
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
        }
        
        try await Auth.auth().signIn(with: credential)
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()

            // reset onboarding state for debugging
            if ProcessInfo.processInfo.environment["DEMO_MODE"] == "1" {
                UserDefaults.standard.set(false, forKey: "hasOnboarded")
            }
            
            UserDefaults.standard.set(OnboardingStep.welcome.rawValue, forKey: "onboardingStep")
            
            print("👋 User signed out successfully")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }


    // MARK: - Nonce Utilities
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with code \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random % UInt8(charset.count))])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
