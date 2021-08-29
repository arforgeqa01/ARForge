//
//  UserModelsState.swift
//  ARForge
//
//  Created by ARForgeQA on 9/2/21.
//

import Foundation
import Combine

enum UserModelsStateValue {
    case unknown
    case error(String)
    case success
    case refreshing
}


class UserModelsState : ObservableObject {
    static let shared = UserModelsState()
    
    @Published var models: [ModelJob] = []
    @Published var currentState = UserModelsStateValue.unknown
    
    var res : Result<[ModelJob], NetworkError> = .failure(.unknown) {
        didSet {
            print("res is \(res)")
            switch res {
            case .success(let models):
                self.currentState = .success
                self.models = models
            case .failure(let err):
                self.currentState = .error(err.description)
                self.models = [];
            }
        }
    }
}
