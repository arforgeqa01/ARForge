//
//  AppleLoginManager.swift
//  ARForge
//
//  Created by ARForgeQA on 10/17/21.
//

import Foundation
import AuthenticationServices
import Firebase
import FirebaseAuth
import CommonCrypto

class AppleLoginManager: NSObject {
    @Published var firUser: User? = nil
    static let shared = AppleLoginManager()
    
    fileprivate var currentNonce: String?
    
    @available(iOS 13, *)
    func startSignInWithAppleFlowWith(hostViewController: UIViewController) {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        var hashData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = hashData.withUnsafeMutableBytes {digestBytes in
            data.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }
        
        return hashData.compactMap {
          return String(format: "%02x", $0)
        }.joined()
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
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if length == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
}


@available(iOS 13.0, *)
extension AppleLoginManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first ?? UIWindow()
    }
    
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      guard let nonce = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identity token")
        return
      }
      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        return
      }
      // Initialize a Firebase credential.
      let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                rawNonce: nonce)
      // Sign in with Firebase.
      Auth.auth().signIn(with: credential) { [weak self] (authResult, err) in
        if let _ = err {
          // Error. If error.code == .MissingOrInvalidNonce, make sure
          // you're sending the SHA256-hashed nonce as a hex string with
          // your request to Apple.
            //self?.hostDelegate?.showAuthenticationError(err: error)
          return
        }
        // User is signed in to Firebase with Apple.
        guard let user = authResult?.user else { return }
        
        self?.firUser = user
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    //hostDelegate?.showAuthenticationError(err: error)
  }

}
