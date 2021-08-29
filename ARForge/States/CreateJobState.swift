//
//  CreateJobState.swift
//  ARForge
//
//  Created by ARForgeQA on 9/2/21.
//

import Foundation
import Combine

enum CreateJobStateValue {
    case editing
    case uploading(String)
    case error(String)
    case success
}

class CreateJobState: ObservableObject {
    @Published var jobStateValue = CreateJobStateValue.editing
    
    var res : Result<CreateJobStateValue, NetworkError> = .failure(.unknown) {
        didSet {
            switch res {
            case .success(let val):
                print("ARForgeQADEBUG Val is \(val)")
                self.jobStateValue = val
            case .failure(let err):
                self.jobStateValue = .error(err.description)
            }
        }
    }
}
