//
//  TodayViewController.swift
//  To-Do Widget
//
//  Created by Wismin Effendi on 8/17/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData
import NotificationCenter
import ToDoCoreDataCloudKit

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var tableView: UITableView!
    
    let coreDataStack = CoreDataStack.shared(modelName: ModelName.ToDo)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        readFromCoreData()
        tableView.dataSource = self
        tableView.delegate = self 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        tableView.reloadData()
        completionHandler(NCUpdateResult.newData)
    }
    
    func readFromCoreData() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let dueDateSort = NSSortDescriptor(key: #keyPath(Task.dueDate), ascending: true)
        let titleSort = NSSortDescriptor(key: #keyPath(Task.title), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [dueDateSort, titleSort]
        do {
            let results = try coreDataStack.managedContext.fetch(fetchRequest)
            print(results.count)
            for result in results {
                print(result)
            }
        } catch let error as NSError {
            print("Error... \(error.debugDescription)")
        }
    }
    
}

// MARK: - TableView Datasource and Delegate
extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WidgetTableViewCell", for: indexPath) as! WidgetTableViewCell
        print("We are here....")
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 59
    }
}


