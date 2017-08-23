//
//  LocationListViewController.swift
//  PlayLocationService
//
//  Created by Wismin Effendi on 8/21/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit
import CoreData

class LocationListViewController: UITableViewController, TaskLocationDelegate {

    var taskLocation = TaskLocation() {
        didSet {
            print("We got \(taskLocation.title)")
            delegate?.taskLocation = taskLocation
        }
    }
    
    var coreDataStack: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<LocationAnnotation>!
    var locationAnnotations = [LocationAnnotation]()
    
    var delegate: TaskLocationDelegate?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        initializeFetchResultsController()
        
        self.navigationItem.title = "Choose Location"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addNewLocation))
    }
    
    
    // MARK: - Helper 
    private func initializeFetchResultsController() {
        let fetchRequest: NSFetchRequest<LocationAnnotation> = LocationAnnotation.fetchRequest()
        let titleSort = NSSortDescriptor(key: #keyPath(LocationAnnotation.title), ascending: true)
        fetchRequest.sortDescriptors = [titleSort]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    func addNewLocation() {
        performSegue(withIdentifier: SegueIdentifier.AddNewLocation, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.AddNewLocation {
            let vc = segue.destination as! MapViewController
            vc.coreDataStack = coreDataStack
            vc.delegate = self 
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            print("What ... ??")
            return 0
        }
        print("Number of rows: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.LocationName, for: indexPath)
        
        configure(cell: cell, for: indexPath)
        return cell
    }
    
    fileprivate func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        let locationAnnotation = fetchedResultsController.object(at: indexPath)
        let taskLocation = locationAnnotation.annotation as! TaskLocation
        cell.textLabel?.text = taskLocation.title
        cell.detailTextLabel?.text = taskLocation.subtitle
    }
 
    // MARK: - Table view delegate 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let locationAnnotation = fetchedResultsController.object(at: indexPath)
        taskLocation = locationAnnotation.annotation as! TaskLocation
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - NSFetchedResultsControllerDelegate
extension LocationListViewController: NSFetchedResultsControllerDelegate {
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
            let cell = tableView.cellForRow(at: indexPath!)
            configure(cell: cell!, for: indexPath!)
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
