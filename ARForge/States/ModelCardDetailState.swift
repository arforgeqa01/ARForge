//
//  ModelCardDetailState.swift
//  ARForge
//
//  Created by ARForgeQA on 10/17/21.
//

import Foundation

enum ModelCardDetailScreenState {
    case initial
    case buying
    case deleting
    
    var loadingString: String {
        switch self {
        case .buying:
            return "Buying the Model. Please wait"
        case .deleting:
            return "Deleting the Model. Please wait"
        default:
            return ""
        }
    }
}

class ModelCardDetailState: ObservableObject {
    static let shared = ModelCardDetailState()
    
    @Published var screenState = ModelCardDetailScreenState.initial
}
