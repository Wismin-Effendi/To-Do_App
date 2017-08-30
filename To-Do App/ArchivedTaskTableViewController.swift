//
//  ArchievedTaskTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/25/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit
import CoreData
import os.log
import MGSwipeTableCell

class ArchivedTaskTableViewController: TaskTableViewController {
    
    // MARK: - Properties
    override var cellIdentifier: String { return CellIdentifier.ArchivedTaskCell }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.title = NavBarTitle.ArchivedTask
        addBarButton.isEnabled = false 
        
        // select the first navigationItem
        selectFirstItemIfExist(archivedView: true)
    }
    
    func selectFirstItemIfExist(archivedView: Bool) {
        if let split = self.splitViewController, split.viewControllers.count == 2  {
            let nc = split.viewControllers.last as! UINavigationController
            self.detailViewController = nc.topViewController as? TaskEditTableViewController
            
            self.delegate.isArchivedView = archivedView
            if let section = fetchedResultsController.sections,
                section.count > 0 {
                self.detailViewController.task = fetchedResultsController.object(at: IndexPath(item: 0, section: 0))
            } else {
                self.detailViewController.task = nil
            }
        }
    }
    
    override func initializeFetchResultsController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let archivedPredicate = NSPredicate(format: "%K == YES", #keyPath(Task.archived))
        let completionDateSort = NSSortDescriptor(key: #keyPath(Task.completionDate), ascending: false)
        let titleSort = NSSortDescriptor(key: #keyPath(Task.title), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [completionDateSort, titleSort]
        fetchRequest.predicate = archivedPredicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.managedContext,
                                                              sectionNameKeyPath: "completionDateType",
                                                              cacheName: nil)
        
        fetchedResultsController.delegate = self
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        let headerText = "\(sectionInfo!.name)"
        return headerText
    }
    
    // Override row selection, we want to automatically save the editing / new task into coredata
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("We are in row selected")
        // save any pending edit on detail view
        self.coreDataStack.saveContext()
        
        let managedContext = coreDataStack.managedContext
        let selectedTask = fetchedResultsController.object(at: indexPath)
        self.delegate?.isArchivedView = true
        self.delegate?.taskSelected(task: selectedTask, managedContext: managedContext)
        
        if let detailViewController = self.delegate as? TaskEditTableViewController {
            splitViewController?.showDetailViewController(detailViewController.navigationController!, sender: nil)
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            let taskToDelete = fetchedResultsController.object(at: indexPath)
            coreDataStack.managedContext.delete(taskToDelete)
            
            do {
                try coreDataStack.managedContext.save()
            } catch {
                print(error)
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        selectFirstItemIfExist(archivedView: true)
    }
}


// MARK: - Internal
extension ArchivedTaskTableViewController {
    override func configure(cell: MGSwipeTableCell, for indexPath: IndexPath) {
        guard let cell = cell as? TaskCell else {
            return
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        let text = task.title
        let attributedString = NSMutableAttributedString(string: text)
        cell.textLabel?.attributedText = noStrikethrough(attributedString)
        let completionDateText = DateUtil.shortDateText(task.completionDate! as Date)
        cell.detailTextLabel?.text = "Completion date: \(completionDateText)"
        
        // configure left buttons
        cell.leftButtons = [MGSwipeButton(title: "Activate", icon: #imageLiteral(resourceName: "cellClockIcon"), backgroundColor: UIColor.blue) {[unowned self]
            (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
            CoreDataUtil.cloneAsActiveTask(task: task, managedContext: self.coreDataStack.managedContext)
            return true
            }]
        cell.leftSwipeSettings.transition = .static
    }
}


