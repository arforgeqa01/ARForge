//
//  DepositIAPReceiptUseCase.swift
//  ARForge
//
//  Created by ARForgeQA on 10/3/21.
//

import Foundation
import Combine

class DepositIAPReceiptUseCase: UseCase {

    var token: String?
    var iapState: IAPState
    var subscriptions = Set<AnyCancellable>()
    let endpoint: FirebaseEndpoint
    
    func start() {
        guard let req = endpoint.urlRequest(token: token) else {
            iapState.res = Result<String, NetworkError>.failure(.unknown)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .decode(type: OutputRes.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map {_ in
                return Result<String, NetworkError>.success("DONE")
            }
            .replaceError(with: Result<String, NetworkError>.failure(.unknown))
            .assign(to: \.res, on: iapState)
            .store(in: &subscriptions)
    }
    
    struct OutputRes : Codable {
        let coins: Int
    }
    

    
    init(endpoint:FirebaseEndpoint, iapState: IAPState, token: String?) {
        self.endpoint = endpoint
        self.iapState = iapState
        self.token = token
    }
    
    static func initializeAndStart(receiptString: String) -> UseCase {
        
        let jsonData = try! JSONSerialization.data(withJSONObject: ["receipt": receiptString], options: .prettyPrinted)

        let newUseCase = DepositIAPReceiptUseCase(endpoint: .addCoinsWithAppleReceipt(jsonData), iapState: IAPState.shared, token: nil)
        
        FirebaseState.shared.firebaseUser?.getIDToken(completion: { token, _ in
            newUseCase.token = token
            newUseCase.start()
        })
        
        return newUseCase
    }
}
