//
//  BuyModelUseCase.swift
//  ARForge
//
//  Created by ARForgeQA on 10/16/21.
//

import Foundation
import Combine

class BuyModelUseCase: UseCase {
    var token: String?
    var userModelState: UserModelsState
    var modelCardDetailState: ModelCardDetailState
    var subscriptions = Set<AnyCancellable>()
    let endpoint: FirebaseEndpoint
    let jobID: String
    
    
    func start() {
        guard let req = endpoint.urlRequest(token: token) else {
            userModelState.res = Result<UserModel, NetworkError>.failure(.unknown)
            return
        }
        modelCardDetailState.screenState = .buying
        
        URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .decode(type: ModelJob.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map { Result<ModelJob, NetworkError>.success($0) }
            .replaceError(with: Result<ModelJob, NetworkError>.failure(.unknown))
            .handleEvents(receiveOutput: { _ in
                self.modelCardDetailState.screenState = .initial
            })
            .assign(to: \.model, on: userModelState)
            .store(in: &subscriptions)
    }

    init(endpoint:FirebaseEndpoint, userModelState: UserModelsState, modelCardDetailState: ModelCardDetailState, token: String?, jobID: String) {
        self.endpoint = endpoint
        self.userModelState = userModelState
        self.modelCardDetailState = modelCardDetailState
        self.token = token
        self.jobID = jobID
    }
    
    static func initializeAndStart(jobID: String) -> UseCase {
        
        let jsonData = try! JSONSerialization.data(withJSONObject: ["jobID": jobID], options: .prettyPrinted)

        let newUseCase = BuyModelUseCase(endpoint: .buyModelRequest(jsonData), userModelState: .shared, modelCardDetailState: .shared, token: nil, jobID: jobID)
        
        FirebaseState.shared.firebaseUser?.getIDToken(completion: { token, _ in
            newUseCase.token = token
            
            DispatchQueue.main.async {
                newUseCase.start()
            }
        })
        
        return newUseCase
    }
}
