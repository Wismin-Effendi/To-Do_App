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
import ChameleonFramework

protocol TaskDetailViewDelegate: class {
    func taskSelected(task: Task?, managedContext: NSManagedObjectContext)
    func addTask(managedContext: NSManagedObjectContext)
    var isArchivedView: Bool { get set }
}

class TaskTableViewController: UITableViewController {

    // MARK: - Properties
    var cellIdentifier: String { return CellIdentifier.DueDateTaskCell }
    
    var coreDataStack: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<Task>!
    
    var isFullVersion = UpgradeManager.sharedInstance.hasUpgraded()
    
    var cloudKitHelper: CloudKitHelper!
    
    weak var delegate: TaskDetailViewDelegate!
    
    weak var detailViewController: TaskEditTableViewController!
    
    var tasks = [Task]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailViewController = (tabBarController as? TabBarViewController)?.detailViewController as! TaskEditTableViewController
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        initializeFetchResultsController()
        tableView.separatorColor = UIColor.flatNavyBlueColorDark()
        tableView.tableFooterView = UIView()
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        
        setupRefreshControl()
        
        // Gesture to enable Editing
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TaskTableViewController.setIsEditing))
        tableView.addGestureRecognizer(longPress)
    }
    
    func saveToCloudKit() {
        DispatchQueue.global(qos: .userInitiated).async {[unowned self] in 
            self.cloudKitHelper.savingToCloudKitOnly()
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Saving to iCloud")
        refreshControl!.addTarget(self, action: #selector(TaskTableViewController.saveToCloudKit), for: .valueChanged)
        tableView.addSubview(refreshControl!)
    }

    // generic should be overriden by subclass
    func initializeFetchResultsController() {
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let dueDateSort = NSSortDescriptor(key: #keyPath(Task.dueDate), ascending: true)
        let titleSort = NSSortDescriptor(key: #keyPath(Task.title), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [dueDateSort, titleSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.managedContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        fetchedResultsController.delegate = self
    }

    
    func setIsEditing() {
        setEditing(true, animated: true)
    }
    
    
    func withinFreeVersionLimit() -> Bool {
        let taskCount = CoreDataUtil.getTaskCount(predicate: Predicates.TaskNotPendingDeletion, moc: coreDataStack.managedContext)
        return taskCount < Constant.MaxFreeVersionTask
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
    
    // MARK: - Tableview delegate 
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.flatWhiteColorDark()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
}

// MARK: - Internal 
extension TaskTableViewController {
    
    func configure(cell: MGSwipeTableCell, for indexPath: IndexPath) {
        guard let cell = cell as? TaskCell else {
            return
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        let text = task.title
        let attributedString = NSMutableAttributedString(string: text)
        cell.textLabel?.attributedText = task.completed ? addThickStrikethrough(attributedString) : noStrikethrough(attributedString)
        let dueDateText = DateUtil.shortDateText(task.dueDate as Date)
        cell.detailTextLabel?.text = dueDateText
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        cell.backgroundColor = UIColor.flatWhite()
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


extension TaskTableViewController: ProductUpgraded {
    
    func productHasUpgradeAction() {
        guard UpgradeManager.sharedInstance.hasUpgraded() else { return }
        navigationController?.popViewController(animated: true)
    }
}
