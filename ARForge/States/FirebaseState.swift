//
//  FirebaseState.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//

import Foundation
import Firebase
import Combine

enum FirebaseUserStateValue {
    case unknown
    case loggedIn
    case loggedOut
}

class FirebaseState {
    @Published var firebaseUserState = FirebaseUserStateValue.unknown
    
    @Published var firebaseUser : User? = nil {
        didSet {
            firebaseUserState = firebaseUser == nil ? .loggedOut : .loggedIn
        }
    }
    static let shared = FirebaseState()
    var allCancellables = Set<AnyCancellable>()
    
    func initialSetup() {
        startListeningForChanges()

        if let filePath = Bundle.main.path(forResource: "GoogleService-Info_ARForge", ofType: "plist"),
            let firebaseOptions = FirebaseOptions.init(contentsOfFile: filePath) {
            FirebaseApp.configure(options: firebaseOptions)
            firebaseUser = Auth.auth().currentUser
        }
    }
    
    func startListeningForChanges() {
        GoogleLoginManager.shared.$firUser
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if self?.firebaseUser != $0 {
                    self?.firebaseUser = $0
                }
        }.store(in: &allCancellables)
        
        AppleLoginManager.shared.$firUser
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if self?.firebaseUser != $0 {
                    self?.firebaseUser = $0
                }
            }.store(in: &allCancellables)
    }
    
    func logout() {
        try? Auth.auth().signOut()
        firebaseUser = nil
        GoogleLoginManager.shared.firUser = nil
    }
    
}
