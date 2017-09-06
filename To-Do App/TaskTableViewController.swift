 //
//  TaskTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/26/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
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
        self.edgesForExtendedLayout = []
        self.view.backgroundColor = UIColor.flatWhite()
        self.detailViewController = (tabBarController as? TabBarViewController)?.detailViewController as! TaskEditTableViewController
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        initializeFetchResultsController()
        tableView.estimatedRowHeight = 48.0
        tableView.rowHeight = UITableViewAutomaticDimension
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateFromWidget()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.coreDataStack.saveContext()
    }
    
    private func updateFromWidget() {
        // check if there are any completed task from Today Extension
        // update the main managedObjectContext accordingly
        
        guard let userDefault = UserDefaults(suiteName: UserDefaults.appGroup),
            let completedFromTodayExtension = userDefault.array(forKey: UserDefaults.Keys.completedInTodayExtension) as! [String]?
            else { return }
        
        print("The identifiers we got:... \(completedFromTodayExtension)")
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = coreDataStack.managedContext
        CoreDataUtil.updateTaskCompletionFor(identifiers: completedFromTodayExtension, moc: childContext)
        userDefault.set(nil, forKey: UserDefaults.Keys.completedInTodayExtension)
         userDefault.synchronize()
    }
    
    func saveToCloudKit() {
        DispatchQueue.global(qos: .userInitiated).async {[unowned self] in 
            self.cloudKitHelper.savingToCloudKitOnly()
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    func syncToCloudKit() {
        if coreDataStack.managedContext.hasChanges {
            try? coreDataStack.managedContext.save()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {[unowned self] in
            self.cloudKitHelper.syncToCloudKit {
                DispatchQueue.main.async {[unowned self] in
                    self.tableView.reloadData()
                }
            }
        }
        let delayTime = DispatchTime.now() + 1
        DispatchQueue.global().asyncAfter(deadline: delayTime) {[unowned self] in
            DispatchQueue.main.async {[unowned self] in
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Sync to iCloud")
        refreshControl!.addTarget(self, action: #selector(TaskTableViewController.syncToCloudKit), for: .valueChanged)
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
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = coreDataStack.managedContext
        let taskCount = CoreDataUtil.getTaskCount(predicate: Predicates.TaskNotPendingDeletion, moc: childContext)
        print("Number of task: \(taskCount)")
        return taskCount < Constant.MaxFreeVersionTask
    }
    
    func segueToInAppPurchase() {
        guard !UpgradeManager.sharedInstance.hasUpgraded() else {
            productHasUpgradeAction()
            return
        }
        let alertController = UIAlertController(title: NSLocalizedString("Please Upgrade", comment: "Alert prompt"),
                                                message: NSLocalizedString("Free Version has limit of 20 tasks.", comment: "alert message"),
                                                preferredStyle: .alert)
        
        let upgradeAction = UIAlertAction(title: NSLocalizedString("Upgrade", comment: "alert action"),
                                          style: .default,
                                          handler: { (action) in
                                            self.performSegue(withIdentifier: SegueIdentifier.ShowUpgradeViewController, sender: nil)
        })
        
        let laterAction = UIAlertAction(title: NSLocalizedString("Later", comment: "alert action"),
                                        style: .cancel,
                                        handler: nil)
        
        alertController.addAction(upgradeAction)
        alertController.addAction(laterAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.ShowUpgradeViewController {
            let upgradeNavCon = segue.destination as! UINavigationController
            upgradeNavCon.transitioningDelegate = self
        }
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
        let dueText = NSLocalizedString("Due", comment: "subtitle")
        cell.detailTextLabel?.text = "\(dueText): \(dueDateText)"
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        cell.backgroundColor = UIColor.flatWhite()
        // configure left buttons
        cell.leftButtons = [MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "checked"), backgroundColor: .white, callback: {[unowned self]
            (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
            task.setDefaultsForCompletion()
            if DateUtil.isInThePastDays(date: task.dueDate as Date) { task.archived = true }
            Mixpanel.mainInstance().people.increment(property: "completed task", by: 1)
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            return true
        }), MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "archive-custom"), backgroundColor: UIColor.init(hexString: "C8F7C5"), callback: {[unowned self] (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
            task.setDefaultsForLocalChange()
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        case .move:
            break 
        case .update:
            tableView.reloadSections(indexSet, with: .automatic)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}


extension TaskTableViewController: ProductUpgraded {
    
    func productHasUpgradeAction() {
        guard UpgradeManager.sharedInstance.hasUpgraded() else { return }
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - UIViewControllerTransitioningDelegate
extension TaskTableViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomDismissAnimator()
    }
}
