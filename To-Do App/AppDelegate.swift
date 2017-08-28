//
//  AppDelegate.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit
import UserNotifications
import CoreData
import MapKit
import Mixpanel
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    var controller: UIViewController?

    var locationManager: CLLocationManager?
    
    lazy var coreDataStack = CoreDataStack.shared(modelName: ModelName.ToDo)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        setupMixPanel()
        
        setupViewControllers()
        
        application.registerForRemoteNotifications()
                
        requestAuthorizationForUserNotification()
        
        return true
        
    }
    
    private func requestAuthorizationForUserNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options:
        [[.alert, .sound,. badge]]) { (granted, error) in
            if error != nil {
                os_log("Error when requesting notification %s", error!.localizedDescription)
            }
            if !granted { os_log("Permission for user notification was not granted.") }
        }
    }
    
    private func setupViewControllers() {
        // Case of SplitView controller
        let splitViewController = window?.rootViewController as? UISplitViewController
        let navController = splitViewController?.viewControllers.first as? UINavigationController
        let tabBarViewController = navController?.topViewController as? TabBarViewController
        
        splitViewController?.delegate = self
        tabBarViewController?.selectedIndex = 0
        tabBarViewController?.coreDataStack = coreDataStack
        controller = tabBarViewController?.selectedViewController
        
        if let detailNavController = splitViewController?.viewControllers.last as? UINavigationController,
            let taskViewController = detailNavController.topViewController as? TaskEditTableViewController {
            taskViewController.managedContext = coreDataStack.managedContext
            tabBarViewController?.detailViewController = taskViewController
            if  let nc = tabBarViewController?.viewControllers?[0] as? UINavigationController,
                let dueDateTaskViewController = nc.topViewController as? DueDateTaskTableViewController {
                dueDateTaskViewController.coreDataStack = coreDataStack
                dueDateTaskViewController.delegate = taskViewController
            }
            if let nc = tabBarViewController?.viewControllers?[1] as? UINavigationController,
                let locationBasedTaskViewController = nc.topViewController as? LocationTaskTableViewController {
                locationBasedTaskViewController.coreDataStack = coreDataStack
                locationBasedTaskViewController.delegate = taskViewController
            }
            if let nc = tabBarViewController?.viewControllers?[2] as? UINavigationController,
                let archivedTaskTableViewController = nc.topViewController as? ArchivedTaskTableViewController {
                archivedTaskTableViewController.coreDataStack = coreDataStack
                archivedTaskTableViewController.delegate = taskViewController
            }

        }
    }
    
    private func setupMixPanel() {
        // Mixpanel analytics
        Mixpanel.initialize(token: "17c93a8fd533e37f8885e1177f8cf1d5")
        let mixpanel = Mixpanel.mainInstance()
        // maybe better to use iCloud user identifier, but what if user not logged in.
        // for our purpose tracking one device as one user might be okay for now.
        let newUUIDString = UUID().uuidString
        let mixpanelIdentity = UserDefaults.standard.string(forKey: UserDefaults.Keys.mixpanelIdentity) ?? newUUIDString
        if mixpanelIdentity == newUUIDString {
            UserDefaults.standard.set(mixpanelIdentity, forKey: UserDefaults.Keys.mixpanelIdentity)
        }
        mixpanel.identify(distinctId: mixpanelIdentity)
        mixpanel.people.setOnce(properties: ["add new task": 0 , "completed task" : 0])
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveContext()
    }


    // MARK: UISplitViewControllerDelegate 
    
    // always show MasterView first in Compact width
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        return true
    }

}

// MARK: - Remote Notification 
extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for remote notification")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Remote notification registration failed")
        controller?.showAlertWarning(message: "Please login to iCloud for remote data sync.")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Received push")
        completionHandler(.newData)
    }
}

