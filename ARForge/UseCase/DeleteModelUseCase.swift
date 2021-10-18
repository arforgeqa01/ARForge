//
//  DeleteModelUseCase.swift
//  ARForge
//
//  Created by ARForgeQA on 10/17/21.
//


import Foundation
import Combine

class DeleteModelUseCase: UseCase {
    var token: String?
    var userModelState: UserModelsState
    var subscriptions = Set<AnyCancellable>()
    let endpoint: FirebaseEndpoint
    let jobID: String
    
    
    /*
     {
       "status": true
     }
     */
    struct DeleteJobResponse: Codable {
        var status: Bool
        var jobID: String?
    }
    
    func start() {
        guard let req = endpoint.urlRequest(token: token) else {
            userModelState.res = Result<UserModel, NetworkError>.failure(.unknown)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .decode(type: DeleteJobResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map { Result<DeleteJobResponse, NetworkError>.success(DeleteJobResponse(status: $0.status, jobID: self.jobID)) }
            .replaceError(with: Result<DeleteJobResponse, NetworkError>.failure(.unknown))
            .assign(to: \.deleteModel, on: userModelState)
            .store(in: &subscriptions)
    }

    init(endpoint:FirebaseEndpoint, userModelState: UserModelsState, token: String?, jobID: String) {
        self.endpoint = endpoint
        self.userModelState = userModelState
        self.token = token
        self.jobID = jobID
    }
    
    static func initializeAndStart(jobID: String) -> UseCase {
        
        let jsonData = try! JSONSerialization.data(withJSONObject: ["jobID": jobID], options: .prettyPrinted)

        let newUseCase = DeleteModelUseCase(endpoint: .deleteJobRequest(jsonData), userModelState: .shared, token: nil, jobID: jobID)
        
        FirebaseState.shared.firebaseUser?.getIDToken(completion: { token, _ in
            newUseCase.token = token
            newUseCase.start()
        })
        
        return newUseCase
    }
}
