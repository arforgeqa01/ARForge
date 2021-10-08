//
//  IAPState.swift
//  ARForge
//
//  Created by ARForgeQA on 10/3/21.
//

import Foundation
import Combine

enum BuyState {
    case initial
    case inProgress(String)
    case purchased(Data)
    case depositedOnServer
    case failedOnServer(String)
}

class IAPState: ObservableObject {
    static let shared = IAPState()
    
    @Published var buyState = BuyState.initial
    
    var res : Result<String, NetworkError> = .failure(.unknown) {
        didSet {
            switch res {
            case .success(_):
                self.buyState = .depositedOnServer
            case .failure(let err):
                self.buyState = .failedOnServer(err.localizedDescription)
            }
        }
    }
}
