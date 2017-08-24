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
import ToDoCoreDataCloudKit

class TabBarViewController: UITabBarController {

    var coreDataStack: CoreDataStack!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let timeBasedTaskViewController = viewControllers?[0] as? TaskTableViewController {
            timeBasedTaskViewController.coreDataStack = coreDataStack
        }
        if let locationBasedTaskViewController = viewControllers?[1] as? LocationTaskTableViewController {
            locationBasedTaskViewController.coreDataStack = coreDataStack
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        switch (segue.identifier ?? "") {
        case "AddTask":
            os_log("Adding a new task.", log: OSLog.default, type: .debug)
            guard let navCon = segue.destination as? UINavigationController,
                let taskEditTableViewController = navCon.topViewController as? TaskEditTableViewController  else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            Mixpanel.mainInstance().people.increment(property: "add new task", by: 1)
            taskEditTableViewController.managedContext = coreDataStack.managedContext
        default:
            fatalError("Unexpected segue identifier: \(segue.identifier)")
        }
    }
    

}
