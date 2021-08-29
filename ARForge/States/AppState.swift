//
//  AppState.swift
//  ARForge
//
//  Created by ARForgeQA on 8/30/21.
//

import Foundation
import Combine

enum AppScreenValue {
    case unknown
    case login
    case onboarding
    case mainLanding
}

class AppState : ObservableObject {
    static let shared = AppState()
    
    @Published public private(set) var appScreenValue = AppScreenValue.unknown
    
    private var allCancellables = Set<AnyCancellable>()
    private var firebaseUserStateValue = FirebaseUserStateValue.unknown {
        didSet {
            updateAppScreenValue()
        }
    }
    private var onboardingValue = OnboardingValue.unknown {
        didSet {
            updateAppScreenValue()
        }
    }
    
    func initialSetup() {
        startListeningForChanges()
        FirebaseState.shared.initialSetup()
        OnboardingState.shared.initialSetup()
    }
    
    func startListeningForChanges() {
        FirebaseState.shared.$firebaseUserState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.firebaseUserStateValue = $0
            }.store(in: &allCancellables)
        
        OnboardingState.shared.$onboardingValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.onboardingValue = $0
            }.store(in: &allCancellables)
    }
    
    func updateAppScreenValue() {
        var newScreenValue = AppScreenValue.unknown
        
        if (firebaseUserStateValue == .loggedIn && onboardingValue == .done) {
            newScreenValue = .mainLanding
        } else if (firebaseUserStateValue == .loggedIn && onboardingValue == .pending) {
            newScreenValue = .onboarding
        } else if (firebaseUserStateValue == .loggedOut) {
            newScreenValue = .login
        }
        
        if appScreenValue != newScreenValue {
            appScreenValue = newScreenValue
        }
    }
}
