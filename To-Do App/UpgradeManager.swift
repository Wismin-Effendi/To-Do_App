//
//  UpgradeManager.swift
//  WeatherForecast
//
//  Created by Wismin Effendi on 8/8/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation
import StoreKit
import os.log

class UpgradeManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let sharedInstance = UpgradeManager()
    let productIdentifier = "ninja.pragprog.Todododo.fullversion"
    let userDefaultsKey = "HasUpgradedUserDefaultsKey"
    
    typealias SuccessHandler = (_ succeeded: Bool) -> (Void)
    var upgradeCompletionHandler: SuccessHandler?
    var restoreCompletionHandler: SuccessHandler?
    var priceCompletionHandler: ((_ price: Float) -> Void)?
    var famousQuotesProduct: SKProduct?
    
    
    func hasUpgraded() -> Bool {
        let upgraded = UserDefaults.standard.bool(forKey: userDefaultsKey)
        os_log("User has upgrade?: %@", upgraded as CVarArg)
        return upgraded
    }
    
    func upgrade(_ success: @escaping SuccessHandler) {
        upgradeCompletionHandler = success
        SKPaymentQueue.default().add(self)
        
        if let product = famousQuotesProduct {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    func restorePurchases(_ success: @escaping SuccessHandler) {
        restoreCompletionHandler = success
        SKPaymentQueue.default().add(self)
        
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func priceForUpgrade(_ success: @escaping (_ price: Float) -> Void) {
        priceCompletionHandler = success
        
        let identifiers: Set<String> = [productIdentifier]
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        request.start()
    }
    
    // MARK: SKPaymentTransactionObserver
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                UserDefaults.standard.set(true, forKey: userDefaultsKey)
                upgradeCompletionHandler?(true)
            case .restored:
                UserDefaults.standard.set(true, forKey: userDefaultsKey)
                restoreCompletionHandler?(true)
            case .failed:
                os_log("Failed transaction...")
                upgradeCompletionHandler?(false)
            default:
                os_log("Fall through transaction...")
                return
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
    
    // MARK: SKProductsRequestDelegate
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        os_log("Product request: response = %@", response)
        famousQuotesProduct = response.products.first
        
        if let price = famousQuotesProduct?.price {
            priceCompletionHandler?(Float(price))
        }
    }
}
