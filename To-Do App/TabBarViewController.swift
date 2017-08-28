//
//  TabBarViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/24/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import os.log
import Mixpanel
import UserNotifications
import ToDoCoreDataCloudKit

class TabBarViewController: UITabBarController {

    var coreDataStack: CoreDataStack!

    @IBOutlet weak var addBarButton: UIBarButtonItem!
    
    weak var detailViewController: TaskDetailViewDelegate!
    
    
    @IBAction func addNewTaskTapped() {
        let managedContext = coreDataStack.managedContext
        self.detailViewController?.addTask(managedContext: managedContext)
        
        if let detailViewController = self.delegate as? TaskEditTableViewController {
            splitViewController?.showDetailViewController(detailViewController.navigationController!, sender: nil)
        }
    }
}
