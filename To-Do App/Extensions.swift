//
//  Extensions.swift
//  LocalNotification_Exercise
//
//  Created by Wismin Effendi on 7/12/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit

extension UIViewController {
    func showAlertError(message: String) {
        let alertController = UIAlertController(title: NSLocalizedString("Error:", comment:""), message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:""), style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWarning(message: String) {
        let alertController = UIAlertController(title: NSLocalizedString("Warning:", comment:""), message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension Sample {
    func test() -> Bool {
        return true
    }
}
