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
import UserNotifications


class TaskEditTableViewController: UITableViewController, TaskLocationDelegate {

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
    @IBOutlet weak var editLocationButton: UIButton!
    
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var reminderDatePicker: UIDatePicker!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationSubtitleLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var completionDateLabel: UILabel!
    
    var managedContext: NSManagedObjectContext!
    
    var isSplitView = false
    
    var isArchivedView = false
    
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
            tableView.beginUpdates()
            self.refreshUI()
            tableView.endUpdates()
        }
    }
    var location: LocationAnnotation? {
        didSet {
            guard let annotation = location?.annotation as? TaskLocation else { return }
            locationTitle.text = annotation.title
            locationSubtitle.text = annotation.subtitle
            print("\(annotation.title)  at \(annotation.subtitle) of \(annotation)")
            os_log("We got %@ at %@", locationTitle.text!, locationSubtitle.text!)
        }
    }
    
    // TaskLocationDelegate
    var taskLocation = TaskLocation()     
    var locationIdenfifier = "" {
        didSet {
            print("we have new locationIdentifier")
            tableView.reloadData()
        }
    }
    
    // App Delegate 
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editLocationButton.backgroundColor = UIColor.clear
        editLocationButton.tintColor = UIColor.flatSkyBlue()
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
        guard let task = task else {
            navigationItem.title = "No Data"
            return
        }
        print("We are inside the archive label assignment....")
        navigationItem.title = task.title
        taskNameLabel.text = task.title
        locationTitleLabel.text = task.location?.title
        location = task.location
        dueDateLabel.text =  formatDateText(task.dueDate as Date)
        completionDateLabel.text = formatDateText(task.completionDate! as Date)
    }
    
    func refreshUI() {
        if isArchivedView {
            setLabelsForArchiveView()
            hideNavBarButtons()
        } else {
            nonArchiveRefreshUI()
        }
    }
    
    func hideNavBarButtons() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func nonArchiveRefreshUI() {
        guard taskNameTexField != nil else { return } // skip if called before viewDidLoad
        if let task = task {
            os_log("Task: %@", log: OSLog.default, type: OSLogType.debug, task)
            navigationItem.title = task.title 
            taskNameTexField.text = task.title
            location = task.location
            let taskDueDate = task.dueDate as Date
            self.dueDate = taskDueDate
            self.dueDatePicker.date = taskDueDate
            
            reminder.isOn = task.reminder
            reminderSwitchState(reminder)
            if let reminderDate = task.reminderDate as Date? {
                self.reminderDate = reminderDate
                self.reminderDatePicker.date = reminderDate
            }
            
        } else {
            navigationItem.title = "No Data"
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
        cancelButton.title = isSplitView ? "" : "Cancel"
        // also the cancel and save button has dependency on isSplitView value.
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
        guard !isSplitView else { return }
        self.navigationController?.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let task = task else { return }
        let title = taskNameTexField.text ?? ""
        task.title = title
        task.dueDate = (dueDate as NSDate?)!
        task.location = location
        task.reminder = reminder.isOn
        task.reminderDate = reminderDate as? NSDate
        
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
        
        let identifier = task.identifier
        if task.reminder {
            let reminderDate = task.reminderDate! as Date
            appDelegate?.scheduleNotification(at: reminderDate, identifier: identifier, title: "ToDo Reminder", body: task.title)
        } else {
            // cancel any pending notification by identifier
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        
        if !isSplitView {
            self.navigationController?.navigationController?.popToRootViewController(animated: true)
        } else {
            // access MasterView and select first row again
            askMasterViewToSelectFirstRow()
        }
    }
    
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateSplitViewSetting()
    }
    
    
    // MARK: Private Methods
    fileprivate func updateSaveButtonState() {
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        // Disable the Save button if the text field is empty
        let text = taskNameTexField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    fileprivate func askMasterViewToSelectFirstRow() {
        guard let split = self.splitViewController,
            let nc = split.viewControllers.first as? UINavigationController,
            let tabBarViewController = nc.topViewController as? TabBarViewController else { return }
        
        switch tabBarViewController.selectedIndex {
        case 0:
            if  let nc = tabBarViewController.viewControllers?[0] as? UINavigationController,
                let dueDateTaskViewController = nc.topViewController as? DueDateTaskTableViewController {
                dueDateTaskViewController.selectFirstItemIfExist(archivedView: false)
            }
        case 1:
            if let nc = tabBarViewController.viewControllers?[1] as? UINavigationController,
                let locationBasedTaskViewController = nc.topViewController as? LocationTaskTableViewController {
                locationBasedTaskViewController.selectFirstItemIfExist(archivedView: false)
            }
        default: break
        }
    }
    
    // MARK: - Table view delegate 
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard task != nil else { return 0 }   // hide all rows if no data
        // Section 1: Location, Section 3: due DatePicker, only show one at anytime.
        // section 0 - 3 should be hidden for archive task view
        let section = indexPath.section
        let row = indexPath.row
        let noLocationData = (location == nil)
        guard !isArchivedView else {
            print("****** we are in archived view *****")
            return (section < 4) ?  0 : super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        switch(showDueDatePicker, showReminderDate, showReminderDatePicker, noLocationData, section, row) {
        case (false, _, _, _, 2, 1): return 0
        case (_, false, _, _, 3, 1): fallthrough
        case (_, false, _, _, 3, 2): return 0
        case (_, true, false, _, 3, 2): return 0
        case (_, _, _, true, 1, 1): return 0  
        case (_, _, _, _, 4, _): return 0
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section > 0 {
            updateSaveButtonState()
            navigationItem.title = taskNameTexField.text
        }
    }
    
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

extension TaskEditTableViewController: TaskDetailViewDelegate {
    func taskSelected(task: Task?, managedContext: NSManagedObjectContext) {
        self.task = task
        self.managedContext = managedContext
    }
    
    func addTask(managedContext: NSManagedObjectContext) {
        self.task = Task(context: managedContext)
        task?.setDefaultsForLocalCreate()
        nonArchiveRefreshUI()
    }
}

// MARK: - UITextFieldDelegate
extension TaskEditTableViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing Task Name only
        if textField.tag == TextFieldTag.taskName.rawValue {
            saveButton?.isEnabled = false
            editLocationButton?.isEnabled = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        editLocationButton.isEnabled = saveButton.isEnabled
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

