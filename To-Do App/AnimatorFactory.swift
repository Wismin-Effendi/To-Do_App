//
//  AnimatorFactory.swift
//  Todododo
//
//  Created by Wismin Effendi on 9/5/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import os.log

class AnimatorFactory {

    static func scaleUp(view: UIView) -> UIViewPropertyAnimator {
        let scale = UIViewPropertyAnimator(duration: 0.33, curve: .easeIn)
        scale.addAnimations {
            view.alpha = 1.0
        }
        scale.addAnimations({
            view.transform = CGAffineTransform.identity
        }, delayFactor: 0.33)
        scale.addCompletion { (_) in
            os_log("finished animation", log: OSLog.default, type: OSLogType.debug)
        }
        return scale
    }
    
    static func scaleDown(view: UIView) -> UIViewPropertyAnimator {
        let scale = UIViewPropertyAnimator(duration: 0.33, curve: .easeOut)
        scale.addAnimations {
            view.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
            view.alpha = 0
        }
        return scale
    }
}
