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
import CoreData
import UserNotifications
import ToDoCoreDataCloudKit

class TabBarViewController: UITabBarController {

    var coreDataStack: CoreDataStack!
    
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    
    weak var detailViewController: TaskDetailViewDelegate!
    
    
    @IBAction func addNewTaskTapped() {
        
        if withinFreeVersionLimit() {
            let managedContext = coreDataStack.managedContext
            self.detailViewController?.addTask(managedContext: managedContext)
            
            if let detailViewController = self.detailViewController as? TaskEditTableViewController {
                print("We are inside here...")
                splitViewController?.showDetailViewController(detailViewController.navigationController!, sender: nil)
            }
        } else {
            // show pop up 
        }
    }
    
    private func withinFreeVersionLimit() -> Bool {
        let taskCount = CoreDataUtil.getTaskCount(predicate: Predicates.TaskNotPendingDeletion, moc: coreDataStack.managedContext)
        return taskCount < Constant.MaxFreeVersionTask
    }
}
