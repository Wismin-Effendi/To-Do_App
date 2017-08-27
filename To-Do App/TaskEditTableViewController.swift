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

class TaskEditTableViewController: UITableViewController, TaskLocationDelegate, TaskSelectionDelegate {

    enum TextFieldTag: Int {
        case taskName = 100
        case dueDate
        case reminderDate
    }
    
    
    @IBOutlet weak var taskNameTexField: UITextField!
    @IBOutlet weak var dueDateTextField: UITextField!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var locationSubtitle: UILabel!
    @IBOutlet weak var reminder: UISwitch!
    @IBOutlet weak var reminderDateTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var reminderDatePicker: UIDatePicker!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationSubtitleLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var completionDateLabel: UILabel!
    
    var managedContext: NSManagedObjectContext!
    
    var isSplitView = false
    
    var isArchivedView = false {
        didSet {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    var showDueDatePicker: Bool = false {
        didSet {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    var showReminderDate: Bool = false {
        didSet {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    var showReminderDatePicker: Bool = false {
        didSet {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    var dueDate: Date? {
        didSet {
            if let dueDate = dueDate {
                dueDateTextField.text = formatDateText(dueDate)
            }
        }
    }
    
    var reminderDate: Date? {
        didSet {
            if let reminderDate = reminderDate {
                reminderDateTextField.text = formatDateText(reminderDate)
            }
        }
    }
    
    var task: Task? {
        didSet {
            UIView.animate(withDuration: 0.6) { 
                self.refreshUI()
            }
        }
    }
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
        showReminderDate = reminder.isOn
        showDueDatePicker = false
        showReminderDatePicker = false
        // Set tag on textField of interest only
        taskNameTexField.tag = TextFieldTag.taskName.rawValue
        dueDateTextField.tag = TextFieldTag.dueDate.rawValue
        reminderDateTextField.tag = TextFieldTag.reminderDate.rawValue
        
        // Handle the text fields's user input through delegate callbacks.
        taskNameTexField.delegate = self
        dueDateTextField.delegate = self
        reminderDateTextField.delegate = self
        
        
        
        // Set up views if editing an existing Task
        if isArchivedView {
            print("is archive view..")
            setLabelsForArchiveView()
        } else {
            refreshUI()
            // Enable the Save button only if the text field has a valid Task name
            updateSaveButtonState()
        }
    }
    
    private func setLabelsForArchiveView() {
        guard let task = task else { return }
        print("We are inside the archive label assignment....")
        taskNameLabel.text = task.name
        locationTitleLabel.text = task.location?.title
        if let annotation = task.location?.annotation as? TaskLocation {
            locationTitleLabel.text = annotation.title
            locationSubtitleLabel.text = annotation.subtitle
        }
        dueDateLabel.text =  formatDateText(task.dueDate as Date)
        completionDateLabel.text = formatDateText(task.completionDate! as Date)
    }
    
    func refreshUI() {
        if isArchivedView {
            setLabelsForArchiveView()
            hideNavBarButtons()
        } else {
            nonArchiveRefreshUI()
            // Enable the Save button only if the text field has a valid Task name
            updateSaveButtonState()
        }
    }
    
    func hideNavBarButtons() {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
    }
    
    func nonArchiveRefreshUI() {
        guard taskNameTexField != nil else { return } // skip if called before viewDidLoad
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
                if dueDate != nil { dueDatePicker.date = dueDate! }
            }
        } else {
            navigationItem.title = "New Task"
            clearAllFields()
            dueDate = Date() + 3.hours  // default dueDate for new task.
        }
    }
    
    func taskSelected(task: Task?, managedContext: NSManagedObjectContext) {
        self.task = task
        self.managedContext = managedContext
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
        taskNameTexField.text = nil
        locationTitle.text = nil
        locationSubtitle.text = nil
        reminder.isOn = false
        reminderSwitchState(reminder)
    }
    
    
    // MARK: Action
    
    @IBAction func dueDatePickerValueChange(_ sender: UIDatePicker) {
        dueDate = sender.date
    }
    
    @IBAction func reminderSwitchState(_ sender: UISwitch) {
        showReminderDate = sender.isOn
    }
    
    @IBAction func reminderDatePickerValueChange(_ sender: UIDatePicker) {
        reminderDate = sender.date
    }
    
    fileprivate func formatDateText(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        return dateFormatter.string(from: date)
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
        
        if task == nil {  // add new Task
            task = Task(context: managedContext)
            task!.setDefaultsForLocalCreate()
            task!.ranking = 0 // not really used at this time
        }
        task!.name = name
        task!.dueDate = (dueDate as NSDate?)!
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
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
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
        // Section 1: Location, Section 3: due DatePicker, only show one at anytime.
        // section 0 - 3 should be hidden for archive task view
        let section = indexPath.section
        let row = indexPath.row
        guard !isArchivedView else {
            print("****** we are in archived view *****")
            return (section < 4) ?  0 : super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        switch(showDueDatePicker, showReminderDate, showReminderDatePicker, section, row) {
        case (false, _, _, 2, 1): return 0
        case (_, false, _, 3, 1): fallthrough
        case (_, false, _, 3, 2): return 0
        case (_, true, false, 3, 2): return 0
        case (_, _, _, 4, _): return 0
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
            showReminderDatePicker = false
            showDueDatePicker = !showDueDatePicker
            dueDate = dueDatePicker.date
            return false
        } else if textField.tag == TextFieldTag.reminderDate.rawValue  {
            self.view.endEditing(true) // hide the keyboard
            showDueDatePicker = false
            showReminderDatePicker = !showReminderDatePicker
            reminderDate = reminderDatePicker.date
            return false
        } else {
            showDueDatePicker = false
            showReminderDatePicker = false
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

