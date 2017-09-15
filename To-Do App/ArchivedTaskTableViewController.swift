//
//  ArchievedTaskTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/25/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit
import CoreData
import os.log
import MGSwipeTableCell

class ArchivedTaskTableViewController: TaskTableViewController {
    
    var settingsButton: UIBarButtonItem!
    
    // MARK: - Properties
    override var cellIdentifier: String { return CellIdentifier.customTaskCell }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isArchivedView = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = NavBarTitle.ArchivedTask
        settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(ArchivedTaskTableViewController.settingTapped))
        tabBarController?.navigationItem.rightBarButtonItem = settingsButton
        isArchivedView = true 
        // select the first navigationItem
        selectFirstItemIfExist(archivedView: isArchivedView)
    }
    
    @objc func settingTapped(_ sender: UIBarButtonItem) {
        // need to segue to new page that show settings
        performSegue(withIdentifier: "SettingsViewController", sender: nil)
    }
    
    func selectFirstItemIfExist(archivedView: Bool) {
        if let split = self.splitViewController, split.viewControllers.count == 2 {
            
            let nc = split.viewControllers.last as! UINavigationController
            nc.popToRootViewController(animated: true)
            self.detailViewController = nc.topViewController as? TaskEditTableViewController
            
            guard self.detailViewController != nil else { return }
            
            self.delegate.isArchivedView = archivedView
            let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            childContext.parent = coreDataStack.managedContext
            self.detailViewController.managedContext = childContext
            
            if let section = fetchedResultsController.sections,
                section.count > 0 {
                let taskInParentContext = fetchedResultsController.object(at: IndexPath(item: 0, section: 0))
                let taskInChildContext = childContext.object(with: taskInParentContext.objectID) as! Task
                self.detailViewController.task = taskInChildContext
            } else {
                self.detailViewController.task = nil
            }
        }
    }
    
    override func initializeFetchResultsController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let completionDateSort = NSSortDescriptor(key: #keyPath(Task.completionDate), ascending: false)
        let titleSort = NSSortDescriptor(key: #keyPath(Task.title), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [completionDateSort, titleSort]
        fetchRequest.predicate = Predicates.TaskInArchivedAndNotPendingDeletion
        
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
        // save any pending edit on detail view
        self.coreDataStack.saveContext()
        
        let managedContext = coreDataStack.managedContext
        let selectedTask = fetchedResultsController.object(at: indexPath)
        self.delegate?.isArchivedView = isArchivedView
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = managedContext
        let childTask = childContext.object(with: selectedTask.objectID) as? Task
        self.delegate?.taskSelected(task: childTask, managedContext: childContext)
        
        if let detailViewController = self.delegate as? TaskEditTableViewController {
            splitViewController?.showDetailViewController(detailViewController.navigationController!, sender: nil)
        }
    }
    
    // hide the Editing button when not in editing mode. Need longPress to initiate to editing Mode
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            tabBarController?.navigationItem.rightBarButtonItems = [editButtonItem, settingsButton]
            settingsButton.isEnabled = false
        }
        else {
            tabBarController?.navigationItem.rightBarButtonItems = [settingsButton]
            settingsButton.isEnabled = true
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            let taskToDelete = fetchedResultsController.object(at: indexPath)
            if taskToDelete.ckMetadata != nil {
                taskToDelete.setForLocalDeletion()
            } else {
                coreDataStack.managedContext.delete(taskToDelete)
            }
            coreDataStack.saveContext()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        selectFirstItemIfExist(archivedView: isArchivedView)
    }
}


// MARK: - Internal
extension ArchivedTaskTableViewController {
    override func configure(cell: MGSwipeTableCell, for indexPath: IndexPath) {
        guard let cell = cell as? CustomTaskCell else {
            return
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        let text = task.title
        let attributedString = NSMutableAttributedString(string: text)
        cell.title?.attributedText = noStrikethrough(attributedString)
        let completionDateText = DateUtil.shortDateText(task.completionDate! as Date)
        cell.subtitle?.text = "Completion date: \(completionDateText)"
        cell.backgroundColor = UIColor.flatGray()
        cell.alarmImageView.isHidden = true
        cell.noteImageView.isHidden = task.notes == ""
        cell.disclosureImageView.isHidden = cell.isEditing
        // configure left buttons
        cell.leftButtons = [MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "clock-custom"), backgroundColor: .white) {[unowned self]
            (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? CustomTaskCell) != nil else { return false }
            CoreDataUtil.cloneAsActiveTask(task: task, managedContext: self.coreDataStack.managedContext)
            self.coreDataStack.saveContext()
            return true
            }]
        cell.leftSwipeSettings.transition = .static
    }
}


