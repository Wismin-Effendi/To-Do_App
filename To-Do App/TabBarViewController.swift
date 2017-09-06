//
//  TabBarViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/24/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import os.log
import Mixpanel
import CoreData
import UserNotifications
import ToDoCoreDataCloudKit

class TabBarViewController: UITabBarController {

    var coreDataStack: CoreDataStack!
    
    weak var detailViewController: TaskDetailViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 0
        self.delegate = self
    }
}

extension TabBarViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let customTabBarAnimator = CustomTabBarAnimator()
        customTabBarAnimator.tabBarController = self
        
        return customTabBarAnimator
    }
}
