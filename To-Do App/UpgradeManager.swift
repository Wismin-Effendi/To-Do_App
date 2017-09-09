//
//  UpgradeManager.swift
//  WeatherForecast
//
//  Created by Wismin Effendi on 8/8/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation
import StoreKit
import ToDoCoreDataCloudKit
import os.log

class UpgradeManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let sharedInstance = UpgradeManager()
    let productIdentifier = "ninja.pragprog.Todododo.fullversion"
    let userDefaultsKey = "HasUpgradedUserDefaultsKey"
    
    typealias SuccessHandler = (_ succeeded: Bool) -> (Void)
    var upgradeCompletionHandler: SuccessHandler?
    var restoreCompletionHandler: SuccessHandler?
    var priceCompletionHandler: ((_ price: String) -> Void)?
    var fullVersionTodododoProduct: SKProduct?
    
    
    func hasUpgraded() -> Bool {
        let upgraded = UserDefaults.standard.bool(forKey: userDefaultsKey)
        os_log("User has upgrade?: %@", log: .default, type: .debug, upgraded as CVarArg)
        return upgraded
    }
    
    func upgrade(_ success: @escaping SuccessHandler) {
        upgradeCompletionHandler = success
        SKPaymentQueue.default().add(self)
        
        if let product = fullVersionTodododoProduct {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    func restorePurchases(_ success: @escaping SuccessHandler) {
        restoreCompletionHandler = success
        SKPaymentQueue.default().add(self)
        
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func priceForUpgrade(_ success: @escaping (_ price: String) -> Void) {
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
                os_log("Failed purchase transaction...", log: .default, type: .error)
                upgradeCompletionHandler?(false)
            default:
                os_log("Fall through transaction...", log: .default, type: .debug)
                return
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
    
    // MARK: SKProductsRequestDelegate
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        os_log("Product request: response = %@", log: .default, type: .debug, response)
        fullVersionTodododoProduct = response.products.first
        
        if let price = fullVersionTodododoProduct?.price {
            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = fullVersionTodododoProduct?.priceLocale
            let localPrice = numberFormatter.string(from: price)
            priceCompletionHandler?(localPrice!)
        }
    }
}
