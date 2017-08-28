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
    var isArchivedView: Bool { get set }
}

class TaskTableViewController: UITableViewController {

    // MARK: - Properties
    var cellIdentifier: String { return CellIdentifier.DueDateTaskCell }
    
    var coreDataStack: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<Task>!
    var addBarButton: UIBarButtonItem!
    
    weak var delegate: TaskSelectionDelegate!
    
    weak var detailViewController: TaskEditTableViewController!
    
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
    

    // generic should be overriden by subclass
    func initializeFetchResultsController() {
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let dueDateSort = NSSortDescriptor(key: #keyPath(Task.dueDate), ascending: true)
        let nameSort = NSSortDescriptor(key: #keyPath(Task.name), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [dueDateSort, nameSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.managedContext,
                                                              sectionNameKeyPath: nil,
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
            task.completionDate = NSDate()
            Mixpanel.mainInstance().people.increment(property: "completed task", by: 1)
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            return true
        }), MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "Archive Cell Icon"), backgroundColor: .darkGray, callback: {[unowned self] (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
            task.archived = true
            if !task.completed {
                task.completed = true
                task.completionDate = NSDate()
            }
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            return true
        })]
        cell.leftSwipeSettings.transition = .static
    }
    
    func addThickStrikethrough(_ attributedString: NSMutableAttributedString) -> NSAttributedString {
        attributedString.addAttribute(NSBaselineOffsetAttributeName, value: NSUnderlineStyle.styleNone.rawValue, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.styleThick.rawValue, range: NSMakeRange(0, attributedString.length))
        return attributedString
    }
    
    func noStrikethrough(_ attributedString: NSMutableAttributedString) -> NSAttributedString {
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
