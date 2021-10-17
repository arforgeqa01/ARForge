//
//  IAPState.swift
//  ARForge
//
//  Created by ARForgeQA on 10/3/21.
//

import Foundation
import Combine
import StoreKit

enum BuyState {
    case initial
    case inProgress(String)
    case purchased(Data, SKPaymentTransaction)
    case depositedOnServer
    case failedOnServer(String)
}

class IAPState: ObservableObject {
    static let shared = IAPState()
    var useCase: UseCase?
    
    @Published var buyState = BuyState.initial {
        didSet {
            switch buyState {
            case .purchased(let data, let transaction):
                let base64Str = data.base64EncodedString()
                self.useCase = DepositIAPReceiptUseCase.initializeAndStart(receiptString: base64Str, transaction: transaction)
            default:
                break
            }
        }
    }
    
    var res : Result<UserModel, NetworkError> = .failure(.unknown) {
        didSet {
            switch res {
            case .success(let userModel):
                UserModelsState.shared.userInfo = userModel.getUserInfo()
                self.buyState = .depositedOnServer
            case .failure(let err):
                self.buyState = .failedOnServer(err.localizedDescription)
            }
        }
    }
}
