//
//  TaskEditTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/23/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import ToDoCoreDataCloudKit
import os.log
import CoreData
import Mixpanel
import SwiftDate

class TaskEditTableViewController: UITableViewController, TaskLocationDelegate {

    enum TextFieldTag: Int {
        case taskName = 100
        case category
        case dueDate
    }
    
    
    @IBOutlet weak var taskNameTexField: UITextField!
    @IBOutlet weak var dueDateTextField: UITextField!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var locationSubtitle: UILabel!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var isSplitView = false
    
    var showDatePicker: Bool = false {
        didSet {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    var dueDate: Date? {
        didSet {
            if let dueDate = dueDate {
                setDueDateTextField(dueDate)
            }
        }
    }
    
    var managedContext: NSManagedObjectContext!
    
    var task: Task?
    var location: LocationAnnotation? {
        didSet {
            guard let annotation = location?.annotation as? TaskLocation else { return }
            locationTitle.text = annotation.title
            locationSubtitle.text = annotation.subtitle
        }
    }
    
    // TaskLocationDelegate
    var taskLocation = TaskLocation()     
    var locationIdenfifier = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        showDatePicker = false
        // Set tag on textField of interest only
        taskNameTexField.tag = TextFieldTag.taskName.rawValue
        dueDateTextField.tag = TextFieldTag.dueDate.rawValue
        // Handle the text fields's user input through delegate callbacks.
        taskNameTexField.delegate = self
        dueDateTextField.delegate = self
        
        // Set up views if editing an existing Task
        if task != nil {
            os_log("Task: %@", log: OSLog.default, type: OSLogType.debug, task!)
            navigationItem.title = task?.name
            taskNameTexField.text = task?.name
            if let annotation = task?.location?.annotation as? TaskLocation {
                locationTitle.text = annotation.title
                locationSubtitle.text = annotation.subtitle
            }
            if let taskDueDate = task?.dueDate as Date? {
                dueDate = taskDueDate
                if dueDate != nil { datePicker.date = dueDate! }
            }
        } else {
            dueDate = Date() + 3.hours  // default dueDate for new task.
        }
        
        // Enable the Save button only if the text field has a valid Task name
        updateSaveButtonState()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateSplitViewSetting()
        updateLocationInformation()
    }
    
    
    private func updateLocationInformation() {
        guard locationIdenfifier != "" else { return }
        if let locationAnnotation = CoreDataUtil.locationAnnotation(by: locationIdenfifier, managedContext: managedContext) {
            location = locationAnnotation
        }
    }
    
    private func updateSplitViewSetting() {
        isSplitView = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular
        cancelButton.title = isSplitView ? "Clear All" : "Cancel"
        // also the cancel and save button has dependency on isSplitView value.
    }
    
    private func clearAllFields() {
        taskNameTexField.text = ""
        // dueDateTextField.text = ""
    }
    
    
    // MARK: Action
    
    @IBAction func datePickerValueChange(_ sender: UIDatePicker) {
        dueDate = sender.date
    }
    
    fileprivate func setDueDateTextField(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        dueDateTextField.text = dateFormatter.string(from: date)
    }
    
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // For SplitView
        if isSplitView { // clear all button
            clearAllFields()
        } else {  // cancel button
            self.navigationController?.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let name = taskNameTexField.text ?? ""
        
        // Set the task to be passed to TaskTableViewController after the unwind segue
        if task == nil {  // add new Task
            task = Task(context: managedContext)
            task?.setDefaultsForLocalCreate()
            task!.ranking = 0 // not really used at this time
        }
        task!.name = name
        task!.dueDate = dueDate as NSDate?
        task!.location = location
        
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
        
        if !isSplitView {
            self.navigationController?.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateSplitViewSetting()
    }
    
    
    // MARK: Private Methods
    fileprivate func updateSaveButtonState() {
        // Disable the Save button if the text field is empty
        let text = taskNameTexField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    


    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    
    // MARK: - Table view delegate 
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Section 1: Location, Section 3: DatePicker, only show one at anytime.
        
        let section = indexPath.section
        switch (showDatePicker, section) {
        case (true, 1):
            return 0
        case (false, 3):
            return 0
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.LocationList {
            let vc = segue.destination as! LocationListViewController
            vc.managedContext = managedContext
            vc.delegate = self 
        }
    }
 

}


// MARK: - UITextFieldDelegate
extension TaskEditTableViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing Task Name only
        if textField.tag == TextFieldTag.taskName.rawValue {
            saveButton?.isEnabled = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = taskNameTexField.text
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Special treatment for dueDateTextField only
        if textField.tag == TextFieldTag.dueDate.rawValue {
            self.view.endEditing(true)  // hide the keyboard
            showDatePicker = !showDatePicker
            dueDate = datePicker.date
            return false
        } else {
            showDatePicker = false
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

