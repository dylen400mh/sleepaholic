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
            self.currentUser = user
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
            let authResult = try await Auth.auth().signIn(with: credential)
            print("✅ Signed in with Apple: \(authResult.user.uid)")

        case .failure(let error):
            throw error
        }
    }

    // MARK: - Google Sign-In (Firebase Native OAuth)
    func signInWithGoogle() async throws {
        let provider = OAuthProvider(providerID: "google.com")
        
        return try await withCheckedThrowingContinuation { continuation in
            provider.getCredentialWith(nil) { credential, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let credential = credential else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let user = result?.user {
                        print("✅ Signed in with Google: \(user.uid)")
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: URLError(.unknown))
                    }
                }
            }
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
