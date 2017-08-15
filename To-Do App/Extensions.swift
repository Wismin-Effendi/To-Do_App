//
//  Extensions.swift
//  LocalNotification_Exercise
//
//  Created by Wismin Effendi on 7/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlertError(message: String) {
        let alertController = UIAlertController(title: "Error:", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWarning(message: String) {
        let alertController = UIAlertController(title: "Warning:", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
