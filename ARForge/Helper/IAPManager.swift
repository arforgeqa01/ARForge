//
//  IAPManager.swift
//  ARForge
//
//  Created by ARForgeQA on 9/6/21.
//

import Foundation
import StoreKit
import os


class IAPManager: NSObject {
    static let shared = IAPManager()

    var myProducts : Set<SKProduct> = [];
    
    enum ARForgeProduct: String, CaseIterable {
        case coin10 = "com.arforge.app.ARForge.coins.10"
        case coin100 = "com.arforge.app.ARForge.coins.100"
        
        func getProduct() -> SKProduct? {
            var product: SKProduct? = nil
            IAPManager.shared.myProducts.forEach {
                if $0.productIdentifier == self.rawValue {
                    product = $0
                }
            }
            return product
        }
    }
    
    override init() {
        super.init()
        self.fetchProducts()
        SKPaymentQueue.default().add(self)
    }
    
    func initialize() {
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: Set(ARForgeProduct.allCases.map{$0.rawValue}))
        request.delegate = self
        request.start()
    }
    
    func buy(productID: ARForgeProduct) {
        guard let product = productID.getProduct() else {
            return
        }
        
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
        }
    }
}

extension IAPManager: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing :
                // NO OP
                os_log("ARForgeQADEBUG I am purchasing")
                break
            case .restored:
                os_log("ARForgeQADebug I am in restored")

                //SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .purchased:
//                 call the server with the receipt
                if let receiptData = getReceipt() {
                    let base64Str = receiptData.base64EncodedString()
                    os_log("ARForgeQADebug got the data %s", type: .default, base64Str)
                }
                os_log("ARForgeQADebug I am in Purchased")

                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .failed, .deferred:
                
                os_log("ARForgeQADebug I am in failed or deffered")
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            @unknown default:
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.myProducts = Set(response.products)
    }
    
    func getReceipt() -> Data? {
        guard
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: receiptUrl)
        else {
            return nil
        }
        
        return receiptData
    }
}
