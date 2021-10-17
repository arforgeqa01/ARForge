//
//  GetUserObjectUseCase.swift
//  ARForge
//
//  Created by ARForgeQA on 9/2/21.
//

import Foundation
import Combine

class GetUserObjectUseCase: UseCase {
    
    var userModelState: UserModelsState
    var token: String?
    
    var subscriptions = Set<AnyCancellable>()
    let endPoint: FirebaseEndpoint
    
    func start() {
        guard let req = endPoint.urlRequest(token: token) else {
            userModelState.res = Result<UserModel, NetworkError>.failure(.unknown)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .decode(type: UserModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map {
                return Result<UserModel, NetworkError>.success($0)
            }
            .replaceError(with: Result<UserModel, NetworkError>.failure(.unknown))
            .assign(to: \.res, on: userModelState)
            .store(in: &subscriptions)
    }
    
    init(endpoint:FirebaseEndpoint, userModelState: UserModelsState, token: String?) {
        self.endPoint = endpoint
        self.userModelState = userModelState
        self.token = token
    }
    
    static func initializeAndStart() -> UseCase {
        let newUseCase = GetUserObjectUseCase(endpoint: .getUserObj, userModelState: UserModelsState.shared, token: nil)

        FirebaseState.shared.firebaseUser?.getIDToken(completion: { token, _ in
            newUseCase.token = token
            newUseCase.start()
        })
        
        return newUseCase
    }
}
