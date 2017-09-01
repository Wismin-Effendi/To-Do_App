//
//  TodayViewController.swift
//  To-Do Widget
//
//  Created by Wismin Effendi on 8/17/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData
import os.log
import SwiftDate
import NotificationCenter
import ToDoCoreDataCloudKit

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var tableView: UITableView!
    
    let coreDataStack = CoreDataStack.shared(modelName: ModelName.ToDo)
    
    var todayTasks = [Task]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        tableView.dataSource = self
        tableView.delegate = self
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    override func viewWillAppear(_ animated: Bool) {
        try? readFromCoreData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            preferredContentSize = CGSize(width: 0, height: 280)
        } else {
            preferredContentSize = maxSize
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        do {
            try readFromCoreData()
        } catch {
            completionHandler(NCUpdateResult.failed)
            return
        }
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        tableView.reloadData()
        completionHandler(NCUpdateResult.newData)
    }
    
    func readFromCoreData() throws {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let todayPredicate =  predicateForToday()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [todayPredicate, predicateNotCompleted()])
        let dueDateSort = NSSortDescriptor(key: #keyPath(Task.dueDate), ascending: true)
        let titleSort = NSSortDescriptor(key: #keyPath(Task.title), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [dueDateSort, titleSort]
        do {
            todayTasks = try coreDataStack.managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            os_log("Error when fetch from coreData from Widget: %@", error.debugDescription)
            throw error
        }
    }
    
    private func predicateForToday() -> NSPredicate {
        let now = Date()
        let startOfDay = now.startOfDay as NSDate
        let endOfDay = now.endOfDay as NSDate
        return NSPredicate(format: "dueDate >= %@ AND dueDate <= %@ ", startOfDay, endOfDay)
    }
    
    private func predicateNotCompleted() -> NSPredicate {
        return NSPredicate(format: "%K == NO", #keyPath(Task.completed))
    }
    
    @IBAction func openAppButtonTapped(_ sender: UIButton) {
        let url: URL? = URL(string: "Todododo:")!
        if let appurl = url {
            self.extensionContext!.open(appurl, completionHandler: nil)
        }
    }
}

// MARK: - TableView Datasource and Delegate
extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todayTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WidgetTableViewCell", for: indexPath) as! WidgetTableViewCell
        let task = todayTasks[indexPath.row]
        cell.task = task 
        return cell
    }
    
}


