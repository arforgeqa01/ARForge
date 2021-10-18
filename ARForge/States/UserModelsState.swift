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
    
    func model(from jobID: String) -> ModelJob? {
        for i in 0..<models.count {
            if jobID == models[i].id {
                return models[i]
            }
        }
        return nil
    }
    
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
    
    var model : Result<ModelJob, NetworkError> = .failure(.unknown) {
        didSet {
            switch model {
            case .success(let modelJob):
                var newModels : [ModelJob] = []
                self.models.forEach { job in
                    if job.id == modelJob.id {
                        newModels.append(modelJob)
                    } else {
                        newModels.append(job)
                    }
                }
                self.models = newModels
                break
            case .failure(let err):
                break
            }
        }
    }
    
    var deleteModel : Result<DeleteModelUseCase.DeleteJobResponse, NetworkError> = .failure(.unknown) {
        didSet {
            switch deleteModel {
            case .success(let response):
                var newModels : [ModelJob] = []
                self.models.forEach { job in
                    if job.id == response.jobID {
                        // do nothing
                    } else {
                        newModels.append(job)
                    }
                }
                self.models = newModels
                break
            case .failure(let err):
                break
            }
        }
    }
}
