//
//  DepositIAPReceiptUseCase.swift
//  ARForge
//
//  Created by ARForgeQA on 10/3/21.
//

import Foundation
import Combine
import StoreKit

class DepositIAPReceiptUseCase: UseCase {

    var token: String?
    var iapState: IAPState
    var subscriptions = Set<AnyCancellable>()
    let endpoint: FirebaseEndpoint
    let transaction: SKPaymentTransaction
    
    func start() {
        guard let req = endpoint.urlRequest(token: token) else {
            iapState.res = Result<UserModel, NetworkError>.failure(.unknown)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .decode(type: UserModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map { Result<UserModel, NetworkError>.success($0) }
            .replaceError(with: Result<UserModel, NetworkError>.failure(.unknown))
            .handleEvents(receiveOutput: { _ in
                IAPManager.shared.finishTransaction(transaction: self.transaction)
            })
            .assign(to: \.res, on: iapState)
            .store(in: &subscriptions)
    }
    
    struct OutputRes : Codable {
        let coins: Int
    }
    

    
    init(endpoint:FirebaseEndpoint, iapState: IAPState, token: String?, transaction: SKPaymentTransaction) {
        self.endpoint = endpoint
        self.iapState = iapState
        self.token = token
        self.transaction = transaction
    }
    
    static func initializeAndStart(receiptString: String, transaction: SKPaymentTransaction) -> UseCase {
        
        let jsonData = try! JSONSerialization.data(withJSONObject: ["receipt": receiptString], options: .prettyPrinted)

        let newUseCase = DepositIAPReceiptUseCase(endpoint: .addCoinsWithAppleReceipt(jsonData), iapState: IAPState.shared, token: nil, transaction: transaction)
        
        FirebaseState.shared.firebaseUser?.getIDToken(completion: { token, _ in
            newUseCase.token = token
            newUseCase.start()
        })
        
        return newUseCase
    }
}
