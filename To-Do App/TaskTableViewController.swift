//
//  TaskTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import os.log
import CoreData



class TaskTableViewController: UITableViewController {

    // MARK: - Properties
    fileprivate let cellIdentifier = "TaskCell"
    var coreDataStack: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<Task>!
    
    var tasks = [Task]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeFetchResultsController()
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        
        // Gesture to enable Editing
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TaskTableViewController.setIsEditing))
        tableView.addGestureRecognizer(longPress)
    }
    
    private func initializeFetchResultsController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let prioritySort = NSSortDescriptor(key: #keyPath(Task.priority), ascending: true)
        let rankingSort = NSSortDescriptor(key: #keyPath(Task.ranking), ascending: true)
        let nameSort = NSSortDescriptor(key: #keyPath(Task.name), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [prioritySort, rankingSort, nameSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: coreDataStack.managedContext,
                                                              sectionNameKeyPath: #keyPath(Task.priority),
                                                              cacheName: nil)
        
        fetchedResultsController.delegate = self
    }

    func setIsEditing() {
        setEditing(true, animated: true)
    }
    
    @IBOutlet weak var addBarButton: UIBarButtonItem!

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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TaskCell else {
            fatalError("The dequeed cell is not an instance of TaskCell")
        }

        configure(cell: cell, for: indexPath)

        return cell
    }
    

    // MARK: - UITableViewDelegate 
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        let headerText = "Priority \(sectionInfo!.name)"
        return headerText
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
            navigationItem.rightBarButtonItems = [editButtonItem, addBarButton]
            addBarButton.isEnabled = false
        }
        else {
            navigationItem.rightBarButtonItems = [addBarButton]
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
        
        let taskToMove = fetchedResultsController.object(at: sourceIndexPath)
        
        // Need to stop live update during moving cells around
        self.fetchedResultsController.delegate = nil
        
        let newRanking: Int32
        let destinationSectionLastRowIndex = fetchedResultsController.sections![destinationIndexPath.section].numberOfObjects - 1
        
        if destinationIndexPath.row <= destinationSectionLastRowIndex {
            print("Case move inside, copy the destination ranking")
            let destTask = fetchedResultsController.object(at: destinationIndexPath)
            newRanking = destTask.ranking
            print("Destination task: \(destTask.name!)")
            print("Destination ranking: \(destTask.ranking)")
        }
        // we move beyond last row
        else {
            print("Case move beyond last row..")
            let destTaskMinus1 = fetchedResultsController.object(at: IndexPath(row: destinationSectionLastRowIndex, section: destinationIndexPath.section))
            newRanking = destTaskMinus1.ranking + 1
        }
        print("New ranking for Moved Cell: \(newRanking)")
        let newPriority = Int16(destinationIndexPath.section + 1) // priority start from 1, section start from 0
        print("New priority for Moved Cell: \(newPriority)")
        taskToMove.priority = newPriority
        taskToMove.ranking = newRanking
        
        // Update other rows on both Source and Destionation
        // Case same section
        if sourceIndexPath.section == destinationIndexPath.section {
            handleCellMoveSameSection(source: sourceIndexPath, destination: destinationIndexPath)
        }
        // Different section
        else {
            handleCellMoveDifferentSection(source: sourceIndexPath, destination: destinationIndexPath)
        }

        
        do {
            try coreDataStack.managedContext.save()
        } catch {
            print(error)
        }
        
        // Now we could re-initiate fetchResultsController 
        initializeFetchResultsController()
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
    }
    
    // Helper for  tableView(_:moveRowAt:to)
    private func handleCellMoveSameSection(source: IndexPath, destination: IndexPath) {
        guard source.section == destination.section else {
            fatalError("Call handle cell move same section but sections differs!")
        }
        
        guard source.row != destination.row else { return }  // move in place, nothing to do
        
        // let lastRowIndex = fetchedResultsController.sections![source.section].numberOfObjects - 1
        
        // Case for move up
        if source.row > destination.row {
            print("Case move up same section...")
            // from dest.row up to  source row - 1 => rank #  + 1
            let startRow = destination.row
            let endRow = source.row - 1
            print("startRow: \(startRow) endRow: \(endRow)")
            for row in startRow...endRow {
                let taskObject: Task = fetchedResultsController.object(at: IndexPath(row: row, section: source.section))
                print(taskObject.name!)
                print("original Ranking: \(taskObject.ranking)")
                taskObject.ranking += 1
                print("new Ranking: \(taskObject.ranking)")
                do {
                    try coreDataStack.managedContext.save()
                } catch {
                    print(error)
                }
            }
        }
        // Case move down
        else {
            print("Case move up same section...")
            let startRow = source.row + 1
            let endRow = destination.row
            print("startRow: \(startRow) endRow: \(endRow)")
            for row in startRow...endRow {
                let taskObject: Task = fetchedResultsController.object(at: IndexPath(row: row, section: source.section))
                print(taskObject.name!)
                print("original Ranking: \(taskObject.ranking)")
                taskObject.ranking -= 1
                print("new Ranking: \(taskObject.ranking)")
                do {
                    try coreDataStack.managedContext.save()
                } catch {
                    print(error)
                }
            }
        }
        
    }
    
    private func handleCellMoveDifferentSection(source: IndexPath, destination: IndexPath) {
        guard source.section != destination.section else {
            fatalError("Call handel cell move different section but actually same sections!")
        }
        
        // Handling on Source section 
        handleSourceSectionForMoveToOtherSection(source: source)
        
        // Handling on Destination section
        let destinationLastRowIndex = fetchedResultsController.sections![destination.section].numberOfObjects - 1
        guard destination.row <= destinationLastRowIndex else {
            // insert after last row at destination, nothing to do for other cells
            return
        }
        let destinationStartRow = destination.row
        let destinationEndRow = destinationLastRowIndex
        
        guard destinationStartRow >= destinationEndRow else { return }
        
        for row in destinationStartRow...destinationEndRow {
            let taskObject: Task = fetchedResultsController.object(at: IndexPath(row: row, section: destination.section))
            taskObject.ranking += 1
            do {
                try coreDataStack.managedContext.save()
            } catch {
                print(error)
            }
        }
        
    }
    

    private func handleSourceSectionForMoveToOtherSection(source: IndexPath) {
        // Handling on Source section
        let sourceLastRowIndex = fetchedResultsController.sections![source.section].numberOfObjects - 1
        let sourceStartRow = source.row + 1
        let sourceEndRow = sourceLastRowIndex
        
        // Prevent crash due to move from last row
        guard sourceEndRow >= sourceStartRow else { return }
        for row in sourceStartRow...sourceEndRow {
            let taskObject: Task = fetchedResultsController.object(at: IndexPath(row: row, section: source.section))
            taskObject.ranking -= 1
            do {
                try coreDataStack.managedContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    
    private func moveDownByOneRowAfterDestinationIndexPath(dest: IndexPath, maxRank: Int) {

        let startRank = dest.row + 1
        guard startRank <= maxRank else { return }
        
        for rank in startRank...maxRank {
            let taskObject: Task = fetchedResultsController.object(at: IndexPath(row: rank, section: dest.section))
            print("Going to move down \(taskObject.name)")
            print("Current rank before move: \(taskObject.ranking)")
            taskObject.ranking += 1   // increment ranking will resulted in move row down by one after sorting
            print("New rank after move: \(taskObject.ranking)")
            do {
                try coreDataStack.managedContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func moveUpByOneRowAfterSourceIndexPath(source: IndexPath, maxRank: Int) {

        let startRank = source.row + 1
        guard startRank <= maxRank else { return }
        
        for rank in startRank...maxRank {
            let taskObject: Task = fetchedResultsController.object(at: IndexPath(row: rank, section: source.section))
            print("Going to move up \(taskObject.name)")
            print("Current rank before move: \(taskObject.ranking)")
            taskObject.ranking -= 1   // decrement ranking will resulted in move row down by one after sorting
            print("New rank after move: \(taskObject.ranking)")
            do {
                try coreDataStack.managedContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    // MARK: - Action 
    
    // Do nothing but still needed to unwind
    @IBAction func unwindToTaskList(_ sender: UIStoryboardSegue) {
        // we need to call tableView.reloadData() here. Else it won't update until next app restart. 
        // would be very difficult to figure out where the new Task should be in.
       tableView.reloadData()
       os_log("Need to call tableView.reloadData() after we add section headers", log: OSLog.default, type:. debug)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch (segue.identifier ?? "") {
        case "AddTask":
            os_log("Adding a new task.", log: OSLog.default, type: .debug)
            guard let navCon = segue.destination as? UINavigationController,
                let taskDetailViewController = navCon.topViewController as? TaskViewController  else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            taskDetailViewController.managedContext = coreDataStack.managedContext
        case "ShowDetail":
            guard let navCon = segue.destination as? UINavigationController,
                let taskDetailViewController = navCon.topViewController as? TaskViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            taskDetailViewController.managedContext = coreDataStack.managedContext
            guard let selectedTaskCell = sender as? TaskCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedTaskCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            print("We selected Task at IndexPath: \(indexPath)")
            let selectedTask = fetchedResultsController.object(at: indexPath)
            taskDetailViewController.task = selectedTask
        default:
            fatalError("Unexpected Segue Identifier: \(String(describing: segue.identifier))")
        }
    }

}

// MARK: - Internal 
extension TaskTableViewController {
    
    func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        guard let cell = cell as? TaskCell else {
            return
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = task.name
        let categoryText = task.category ?? "Any"
        let dueDateText = task.dueDate != nil ? "\(task.dueDate!)" : "No due date"
        cell.detailTextLabel?.text = categoryText + " - " + dueDateText
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
