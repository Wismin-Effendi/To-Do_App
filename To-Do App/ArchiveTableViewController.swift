//
//  ArchieveTableViewController.swift
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

class ArchiveTableViewController: UITableViewController {
    
    // MARK: - Properties
    fileprivate let cellIdentifier = CellIdentifier.ArchivedTaskCell
    
    var coreDataStack: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<Task>!
    
    weak var delegate: TaskSelectionDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
        initializeFetchResultsController()
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        
        // Gesture to enable Editing
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(LocationTaskTableViewController.setIsEditing))
        tableView.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.title = NavBarTitle.TaskByLocation
    }
    
    private func initializeFetchResultsController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let archivedPredicate = NSPredicate(format: "%K == YES", #keyPath(Task.archived))
        let completionDateSort = NSSortDescriptor(key: #keyPath(Task.completionDate), ascending: false)
        let nameSort = NSSortDescriptor(key: #keyPath(Task.name), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [completionDateSort, nameSort]
        fetchRequest.predicate = archivedPredicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.managedContext,
                                                              sectionNameKeyPath: "completionDateType",
                                                              cacheName: nil)
        
        fetchedResultsController.delegate = self
    }
    
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
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
    
    
        /*
         // Override to support conditional editing of the table view.
         override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the specified item to be editable.
         return true
         }
         */
        
        /*
         // Override to support editing the table view.
         override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
         if editingStyle == .delete {
         // Delete the row from the data source
         tableView.deleteRows(at: [indexPath], with: .fade)
         } else if editingStyle == .insert {
         // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         }
         }
         */
        
        /*
         // Override to support rearranging the table view.
         override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
         
         }
         */
        
        /*
         // Override to support conditional rearranging of the table view.
         override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the item to be re-orderable.
         return true
         }
         */
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
         }
         */
        
    }


// MARK: - Internal
extension ArchiveTableViewController {
    
    func configure(cell: MGSwipeTableCell, for indexPath: IndexPath) {
        guard let cell = cell as? TaskCell else {
            return
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        let text = task.name
        let attributedString = NSMutableAttributedString(string: text)
        cell.textLabel?.attributedText = task.completed ? addThickStrikethrough(attributedString) : noStrikethrough(attributedString)
        let dueDateText = DateUtil.shortDateText(task.dueDate as Date)
        cell.detailTextLabel?.text = "Due: \(dueDateText)"
        
        // configure left buttons
        cell.leftButtons = [MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "check"), backgroundColor: .green) {[unowned self]
            (sender: MGSwipeTableCell!) -> Bool in
            guard (sender as? TaskCell) != nil else { return false }
            task.completed = true
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            return true
            }]
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
extension ArchiveTableViewController: NSFetchedResultsControllerDelegate {
    
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

