//
//  TaskTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import os.log
import ToDoCoreDataCloudKit
import CoreData
import MGSwipeTableCell
import Mixpanel

protocol TaskSelectionDelegate: class {
    func taskSelected(task: Task?, managedContext: NSManagedObjectContext)
}

class TaskTableViewController: UITableViewController {

    // MARK: - Properties
    fileprivate let cellIdentifier = CellIdentifier.TaskCell
    
    var coreDataStack: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<Task>!
    var addBarButton: UIBarButtonItem!
    
    weak var delegate: TaskSelectionDelegate!
    
    var tasks = [Task]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
        initializeFetchResultsController()
        
        addBarButton = tabBarController?.navigationItem.rightBarButtonItem
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        
        // Gesture to enable Editing
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TaskTableViewController.setIsEditing))
        tableView.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.title = NavBarTitle.TaskByDueDate
    }
    
    private func initializeFetchResultsController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let notInArchivedStatePredicate = NSPredicate(format: "%K == false", #keyPath(Task.archived))
        fetchRequest.predicate = notInArchivedStatePredicate
        let dueDateSort = NSSortDescriptor(key: #keyPath(Task.dueDate), ascending: true)
        let nameSort = NSSortDescriptor(key: #keyPath(Task.name), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [dueDateSort, nameSort]
        
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.managedContext,
                                                              sectionNameKeyPath: "dueDateType",
                                                              cacheName: nil)
    
        fetchedResultsController.delegate = self
    }

    
    func setIsEditing() {
        setEditing(true, animated: true)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return 0
        }
        
        return sectionInfo.numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: TaskCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TaskCell else {
            fatalError("The dequeed cell is not an instance of TaskCell")
        }

        configure(cell: cell, for: indexPath)

        return cell
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
        self.delegate?.taskSelected(task: selectedTask, managedContext: managedContext)
        
        if let detailViewController = self.delegate as? TaskEditTableViewController {
            splitViewController?.showDetailViewController(detailViewController.navigationController!, sender: nil)
        }
        
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
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
    }
    
    
    // hide the Editing button when not in editing mode. Need longPress to initiate to editing Mode
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            tabBarController?.navigationItem.rightBarButtonItems = [editButtonItem, addBarButton]
            addBarButton.isEnabled = false
        }
        else {
            tabBarController?.navigationItem.rightBarButtonItems = [addBarButton]
            addBarButton.isEnabled = true 
        }
    }


    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        os_log("Source indexPath: %@", log: OSLog.default, type: OSLogType.debug, sourceIndexPath as CVarArg)
        
        os_log("Destination indexPath: %@", log: OSLog.default, type: OSLogType.debug, destinationIndexPath as CVarArg)
        
        guard sourceIndexPath != destinationIndexPath else { return }   // same, nothing to move
        
        // Need to stop live update during moving cells around
        self.fetchedResultsController.delegate = nil
        
        handleCellMove(source: sourceIndexPath, destination: destinationIndexPath)
        
        // Now we could re-initiate fetchResultsController 
        initializeFetchResultsController()
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        // reload tableView 
        tableView.reloadData()
    }
    
    private func handleCellMove(source: IndexPath, destination: IndexPath) {
        
        let lastRowIndex = fetchedResultsController.sections![destination.section].numberOfObjects - 1
        let taskObject: Task = fetchedResultsController.object(at: source)
        
        // only need to find the row before and after destination.row if exist
        // then update the dueDate, save to coreData and let the fetchResultsController do it's work
        if destination.row >= lastRowIndex { // more to the last row
            let lastObjectInSection = fetchedResultsController.object(at: IndexPath(row: lastRowIndex,
                                                                                    section: destination.section))
            let dueDateRowBefore = lastObjectInSection.dueDate as Date
            let newDueDate = DateUtil.getDueDateAfterMove(dueDateRowBefore: dueDateRowBefore, dueDateRowAfter: nil)
            taskObject.dueDate = newDueDate as NSDate
        } else if destination.row == 0 { // more to the first row
            let firstObjectInSection = fetchedResultsController.object(at: IndexPath(row: 0,
                                                                                     section: destination.section))
            let dueDateRowAfter = firstObjectInSection.dueDate as Date
            let newDueDate = DateUtil.getDueDateAfterMove(dueDateRowBefore: nil, dueDateRowAfter: dueDateRowAfter)
            taskObject.dueDate = newDueDate as NSDate
        } else if source.row > destination.row { // move down
            let beforeObject = fetchedResultsController.object(at: IndexPath(row: destination.row,
                                                                             section: destination.section))
            let afterObject = fetchedResultsController.object(at: IndexPath(row: destination.row + 1,
                                                                            section: destination.section))
            let dueDateRowBefore = beforeObject.dueDate as Date
            let dueDateRowAfter = afterObject.dueDate as Date
            let newDueDate = DateUtil.getDueDateAfterMove(dueDateRowBefore: dueDateRowBefore, dueDateRowAfter: dueDateRowAfter)
            taskObject.dueDate = newDueDate as NSDate
        } else { // move up
            let beforeObject = fetchedResultsController.object(at: IndexPath(row: destination.row - 1,
                                                                             section: destination.section))
            let afterObject = fetchedResultsController.object(at: IndexPath(row: destination.row,
                                                                            section: destination.section))
            let dueDateRowBefore = beforeObject.dueDate as Date
            let dueDateRowAfter = afterObject.dueDate as Date
            let newDueDate = DateUtil.getDueDateAfterMove(dueDateRowBefore: dueDateRowBefore, dueDateRowAfter: dueDateRowAfter)
            taskObject.dueDate = newDueDate as NSDate
        }

        do {
            try coreDataStack.managedContext.save()
        } catch {
            print(error)
        }
    }
}

// MARK: - Internal 
extension TaskTableViewController {
    
    func configure(cell: MGSwipeTableCell, for indexPath: IndexPath) {
        guard let cell = cell as? TaskCell else {
            return
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        let text = task.name
        let attributedString = NSMutableAttributedString(string: text)
        cell.textLabel?.attributedText = task.completed ? addThickStrikethrough(attributedString) : noStrikethrough(attributedString)
        let dueDateText = DateUtil.shortDateText(task.dueDate as Date)
        cell.detailTextLabel?.text = dueDateText
        
        // configure left buttons
        cell.leftButtons = [MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "check"), backgroundColor: .green, callback: {[unowned self]
            (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
                task.completed = true
                Mixpanel.mainInstance().people.increment(property: "completed task", by: 1)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                return true
        }), MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "Archive Cell Icon"), backgroundColor: .darkGray, callback: {[unowned self] (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
                task.completed = true
                task.archived = true
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                return true
        })]
        cell.leftSwipeSettings.transition = .static
    }
    
    private func addThickStrikethrough(_ attributedString: NSMutableAttributedString) -> NSAttributedString {
        attributedString.addAttribute(NSBaselineOffsetAttributeName, value: NSUnderlineStyle.styleNone.rawValue, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.styleThick.rawValue, range: NSMakeRange(0, attributedString.length))
        return attributedString
    }
    
    private func noStrikethrough(_ attributedString: NSMutableAttributedString) -> NSAttributedString {
        attributedString.addAttribute(NSBaselineOffsetAttributeName, value: NSUnderlineStyle.styleNone.rawValue, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.styleNone.rawValue, range: NSMakeRange(0, attributedString.length))
        return attributedString
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TaskTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! TaskCell
            configure(cell: cell, for: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default: break
        }
    }
}
