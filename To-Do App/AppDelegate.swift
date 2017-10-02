//
//  AppDelegate.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/12/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit
import UserNotifications
import CoreData
import CloudKit
import MapKit
import Mixpanel
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    var controller: UIViewController?

    var locationManager: CLLocationManager?
    var notificationAuthorized: Bool?
    
    lazy var coreDataStack = CoreDataStack.shared(modelName: ModelName.ToDo)
    let cloudKitHelper: CloudKitHelper = CloudKitHelper.sharedInstance
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        configureTheme()
        AppDelegateHelper.setupConfigurationUserDefaults()
        
        setupMixPanel()
        setupViewControllers()
        // CloudKit stuff
        NotificationCenter.default.addObserver(self, selector: #selector(handleCKAccountChange(notification:)), name: NSNotification.Name.CKAccountChanged, object: nil)
        checkThenRunCloudKitSetup(application)
        
        setupUserNotification()
        return true
        
    }
    
    // MARK: - Private
    @objc func handleCKAccountChange(notification: NSNotification) {
        checkThenRunCloudKitSetup()
    }
    
    private func checkThenRunCloudKitSetup(_ application: UIApplication? = nil) {
        self.cloudKitHelper.checkCKAccountStatus {[unowned self] (accountStatus) in
            switch accountStatus {
            case .available:
                self.setupCloudKit()
                DispatchQueue.main.async {
                    
                    os_log("We have valid iCloud account....", log: .default, type: .debug)
                    application?.registerForRemoteNotifications()
                }
            default:
                self.controller?.showAlertWarning(message: NSLocalizedString("Sync feature require iCloud account", comment:""))
            }
        }
    }
    private func setupCloudKit() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async { [unowned self] in
            self.cloudKitHelper.setupCloudKit()
        }
    }
    
    private func setupUserNotification() {
        UserNotificationHelper.requestAuthorization()
        UNUserNotificationCenter.current().delegate = self
        
        let snoozeAction = UNNotificationAction(identifier: "SnoozeTasksAction", title: "Snooze", options: [])
        let category = UNNotificationCategory(identifier: "OverdueTasksCategory", actions: [snoozeAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    
    private func setupViewControllers() {
        // Case of SplitView controller
        let splitViewController = window?.rootViewController as? UISplitViewController
        let navController = splitViewController?.viewControllers.first as? UINavigationController
        let tabBarViewController = navController?.topViewController as? TabBarViewController
        
        splitViewController?.delegate = self
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
                dueDateTaskViewController.cloudKitHelper = cloudKitHelper
            }
            if let nc = tabBarViewController?.viewControllers?[1] as? UINavigationController,
                let locationBasedTaskViewController = nc.topViewController as? LocationTaskTableViewController {
                locationBasedTaskViewController.coreDataStack = coreDataStack
                locationBasedTaskViewController.delegate = taskViewController
                locationBasedTaskViewController.cloudKitHelper = cloudKitHelper
            }
            if let nc = tabBarViewController?.viewControllers?[2] as? UINavigationController,
                let archivedTaskTableViewController = nc.topViewController as? ArchivedTaskTableViewController {
                archivedTaskTableViewController.coreDataStack = coreDataStack
                archivedTaskTableViewController.delegate = taskViewController
                archivedTaskTableViewController.cloudKitHelper = cloudKitHelper
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
        DispatchQueue.global(qos: .utility).async {
            self.cloudKitHelper.syncToCloudKit {
                os_log("Sync to cloudKit during will enter foreground", log: .default, type: .debug)
            }
            AppDelegateHelper.performAchivingAndDeletion(container: self.coreDataStack.storeContainer)
        }
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

// MARK: - LocalNotification 
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // for foreground notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == "SnoozeTasksAction" {
            // Need to reschedule the notification
            let identifier = response.notification.request.identifier
            let content = response.notification.request.content
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (5*60), repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    os_log("Uh oh! We had an error in adding user notification: %@", log: .default, type: OSLogType.error, error.localizedDescription)
                }
            }
        }
        completionHandler()
    }
    
    func scheduleNotification(at date: Date, identifier: String, title: String, body: String) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, era: components.era, year: components.year, month: components.month, day: components.day, hour: components.hour, minute: components.minute, second: components.second)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "OverdueTasksCategory"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                os_log("Uh oh! We had an error when scheduling notification: %@", log: .default, type: OSLogType.error, error.localizedDescription)
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }

}

// MARK: - Remote Notification 
extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        os_log("Registered for remote notification", log: .default, type: .debug)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Skip Code=3010 "remote notifications are not supported in the simulator"
        guard (error as NSError).code != 3010  else { return }
        
        os_log("Remote notification registration failed: %@", log: .default, type: OSLogType.error, error.localizedDescription)
        controller?.showAlertWarning(message: NSLocalizedString("Please login to iCloud for remote data sync.", comment: ""))
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        os_log("Receive notification", log: .default, type: .debug)
        
        let dict = userInfo as! [String: NSObject]
        
        guard let notification: CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary: dict) as?
            CKDatabaseNotification else { return }
        
        DispatchQueue.global(qos: .utility).async {[unowned self] in
            self.cloudKitHelper.fetchChanges(in: notification.databaseScope) {
                os_log("inside completion handler for fetch changes", log: .default, type: .debug)
                completionHandler(.newData)
            }
        }
    }
}

// MARK: - Theme 
extension AppDelegate {
    
    func configureTheme() {
        StyleManager.setUpTheme()
    }
}



