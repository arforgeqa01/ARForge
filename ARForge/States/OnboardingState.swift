//
//  OnboardingState.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//

import Foundation
import Combine

enum OnboardingValue {
    case unknown
    case done
    case pending
}

class OnboardingState: ObservableObject {
    static let shared = OnboardingState()
    
    private let onboardingStateKey = "OnboardingStateKey"
    @Published public private(set) var onboardingValue = OnboardingValue.unknown {
        didSet {
            UserDefaults.standard.set(onboardingValue == .done, forKey: onboardingStateKey)
        }
    }
    
    func initialSetup() {
        onboardingValue = UserDefaults.standard.bool(forKey: onboardingStateKey) ? .done : .pending
    }
    
    func markOnboardingFinished() {
        onboardingValue = .done
    }
}
