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
    
    @Published var userInfo: UserInfo?
    @Published var models: [ModelJob] = []
    @Published var currentState = UserModelsStateValue.unknown
    
    var res : Result<UserModel, NetworkError> = .failure(.unknown) {
        didSet {
            print("res is \(res)")
            switch res {
            case .success(let userModel):
                self.currentState = .success
                self.models = userModel.getModels()
                self.userInfo = userModel.getUserInfo()
                
            case .failure(let err):
                self.currentState = .error(err.description)
                self.models = [];
            }
        }
    }
}
