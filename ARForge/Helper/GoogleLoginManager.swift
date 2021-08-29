//
//  GoogleLoginManager.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//

import Foundation
import GoogleSignIn
import Firebase

class GoogleLoginManager : NSObject, ObservableObject {
    @Published var firUser: User? = nil
    static let shared = GoogleLoginManager()
        
    func startSignInWithGoogleFlowWith(hostViewController: UIViewController?) {
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let hostVC = hostViewController else { return }

        let config = GIDConfiguration(clientID: clientID)
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: hostVC) { [unowned self] user, error in

          if let error = error {
            print("GIDSignin failed with \(error.localizedDescription)")
            return
          }

          guard
            let authentication = user?.authentication,
            let idToken = authentication.idToken
          else {
            return
          }

          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: authentication.accessToken)

          // ...
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                  let authError = error as NSError
                  if authError.code == AuthErrorCode.secondFactorRequired.rawValue {
                    // Multifactor user error
                  } else {
                    print("Got Error \(error.localizedDescription)")
                    return
                  }
                  // ...
                  return
                }
                guard let firUser = authResult?.user else {
                    
                    return
                }
                
                // User is signed in
                // ...
                
                self.firUser = firUser

            }
        }
    }
}
