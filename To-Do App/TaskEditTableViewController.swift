//
//  TaskEditTableViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/23/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
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
    @IBOutlet weak var locationSubtitle: UITextView!
    @IBOutlet weak var reminder: UISwitch!
    @IBOutlet weak var reminderDateTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    
    var saveButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    @IBOutlet weak var editLocationButton: UIButton!
    
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var reminderDatePicker: UIDatePicker!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationSubtitleLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var completionDateLabel: UILabel!
    @IBOutlet weak var notesTextLabel: UILabel!
    
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
    
    // TaskLocationDelegate
    var location: LocationAnnotation? = nil {
        didSet {
            guard location != nil else { return }
            locationInChildCtx = managedContext.object(with: location!.objectID) as? LocationAnnotation
            task?.location = locationInChildCtx
        }
    }
    
    var locationInChildCtx: LocationAnnotation? = nil {
        didSet {
            guard locationInChildCtx != nil,
                let annotation = locationInChildCtx?.annotation as? TaskLocation else {
                clearLocationTitleSubTitle()
                return
            }
            guard task != nil else { return }
            setLocationTitleSubTitle(annotation: annotation)
        }
    }
    
    // App Delegate 
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isSplitView = (self.splitViewController?.viewControllers.count == 2)
        view.backgroundColor = UIColor.flatWhite()
        editLocationButton.backgroundColor = UIColor.clear
        editLocationButton.tintColor = UIColor.flatSkyBlue()
        notesTextView.backgroundColor = UIColor.flatPowderBlue()
        taskNameTexField.backgroundColor = UIColor.flatPowderBlue()
        dueDateTextField.backgroundColor = UIColor.flatPowderBlue()
        reminderDateTextField.backgroundColor = UIColor.flatPowderBlue()
        locationSubtitle.inputView = UIView(frame: .zero) // no keyboard for readonly textfield 
        locationSubtitle.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        reminder.tintColor = UIColor.flatSkyBlue()
        reminder.onTintColor = UIColor.flatSkyBlue()
        showReminderDate = reminder.isOn
        showDueDatePicker = false
        showReminderDatePicker = false
        
        setTagOnTextField()
        setTextFieldDelegate()
        setTextViewDelegate()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSplitViewSetting()
        
        notesTextView.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
        notesTextView.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationBarItems()
        // Set up views if editing an existing Task
        if isArchivedView {
            os_log("is archive view..", log: .default, type: .debug)
            setLabelsForArchiveView()
        } else {
            if isSplitView { refreshUI() }
            // Enable the Save button only if the text field has a valid Task name
            updateSaveButtonState()
        }
        AnimatorFactory.scaleUp(view: notesTextView).startAnimation()
    }
    
    
    private func setupNavigationBarItems() {
        
        self.saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(TaskEditTableViewController.save(_:)))
        self.cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(TaskEditTableViewController.cancel(_:)))
        
        switch (isSplitView, isArchivedView) {
        case (true, false) :
            self.navigationItem.rightBarButtonItem = saveButton
            self.navigationItem.leftBarButtonItem = nil
        case (true, true):
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
        case (false, false):
            self.navigationItem.rightBarButtonItem = saveButton
            self.navigationItem.leftBarButtonItem = cancelButton
        case (false, true):
            self.cancelButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(TaskEditTableViewController.cancel(_:)))
            self.navigationItem.rightBarButtonItem = cancelButton
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    private func clearLocationTitleSubTitle() {
        guard locationTitle != nil else { return }
        locationTitle.text = nil
        locationSubtitle.text = nil
        locationTitleLabel.text = nil
        locationSubtitleLabel.text = nil
    }
    
    private func setLocationTitleSubTitle(annotation: TaskLocation) {
        self.locationTitle.text = annotation.title
        self.locationSubtitle.text = annotation.subtitle
        self.locationTitleLabel.text = annotation.title
        self.locationSubtitleLabel.text = annotation.subtitle
        tableView.reloadData()
    }
    
    private func setTagOnTextField() {
        // Set tag on textField of interest only
        taskNameTexField.tag = TextFieldTag.taskName.rawValue
        dueDateTextField.tag = TextFieldTag.dueDate.rawValue
        reminderDateTextField.tag = TextFieldTag.reminderDate.rawValue
    }
    
    private func setTextFieldDelegate() {
        // Handle the text fields's user input through delegate callbacks.
        taskNameTexField.delegate = self
        dueDateTextField.delegate = self
        reminderDateTextField.delegate = self
    }
    
    private func setTextViewDelegate() {
        notesTextView.delegate = self
    }
    
    private func setLabelsForArchiveView() {
        guard let task = task else {
            navigationItem.title = "No Data"
            return
        }
        navigationItem.title = task.title
        taskNameLabel.text = task.title
        locationInChildCtx = task.location ?? locationInChildCtx
        dueDateLabel.text =  formatDateText(task.dueDate as Date)
        completionDateLabel.text = formatDateText(task.completionDate! as Date)
        notesTextLabel.text = task.notes
    }
    
    func refreshUI() {
        if isArchivedView {
            setLabelsForArchiveView()
        } else {
            nonArchiveRefreshUI()
        }
    }
    
    
    func nonArchiveRefreshUI() {
        guard taskNameTexField != nil else { return } // skip if called before viewDidLoad
        if let task = task {
            os_log("Task: %@", log: OSLog.default, type: OSLogType.debug, task)
            navigationItem.title = task.title 
            taskNameTexField.text = task.title
            locationInChildCtx = task.location ?? locationInChildCtx
            let taskDueDate = task.dueDate as Date
            self.dueDate = taskDueDate
            self.dueDatePicker.date = taskDueDate
            notesTextView.text = task.notes
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
    
    private func updateSplitViewSetting() {
        isSplitView = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular
        setupNavigationBarItems()
    }

    private func updateTaskFromCurrentUserInput() {
        if task != nil {
            task!.title = self.taskNameTexField.text ?? ""
            task!.dueDate = self.dueDate! as NSDate
            task!.notes = self.notesTextView.text
            task!.reminder = self.reminder.isOn
            task!.reminderDate = self.reminderDate! as NSDate
        }
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
        self.managedContext.reset()
        self.navigationController?.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let task = task else { return }
        task.setDefaultsForLocalChange()
        let title = taskNameTexField.text ?? ""
        task.title = title
        task.dueDate = (dueDate! as NSDate)
        task.location = locationInChildCtx
        task.reminder = reminder.isOn
        task.reminderDate = (reminderDate! as NSDate)
        let notes = notesTextView.text ?? ""
        task.notes = notes
        do {
            try managedContext.save()   // this is childContext
            try managedContext.parent?.save()  // this is the main managedObjectContext
        } catch {
            os_log("Erro during save childContext then parentContext %@", log: .default, type: OSLogType.error, error.localizedDescription)
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
        guard saveButton != nil else { return }
        // Disable the Save button if the text field is empty
        let text = taskNameTexField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
        saveButton.tintColor = saveButton.isEnabled ? UIColor.white : UIColor.clear
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
        // section 0 - 4 should be hidden for archive task view
        let section = indexPath.section
        let row = indexPath.row
        let noLocationData = (locationInChildCtx == nil)
        if noLocationData {
            os_log("no location data...", log: .default, type: .debug)
        }
        guard !isArchivedView else {
            return (section < EditTask.Sections.archiveView) ?  0 : super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        switch(showDueDatePicker, showReminderDate, showReminderDatePicker, noLocationData, section, row) {
        case (false, _, _, _, EditTask.Sections.dueDate, 1): return 0
        case (_, false, _, _, EditTask.Sections.reminder, 1): fallthrough
        case (_, false, _, _, EditTask.Sections.reminder, 2): return 0
        case (_, true, false, _, EditTask.Sections.reminder, 2): return 0
        case (_, _, _, true, EditTask.Sections.location, 1): return 0
        case (_, _, _, _, EditTask.Sections.archiveView, _): return 0
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section > 0 {
            updateSaveButtonState()
            navigationItem.title = taskNameTexField.text
            editLocationButton.isEnabled = saveButton.isEnabled
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.flatWhite()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.LocationList {
            updateTaskFromCurrentUserInput()
            let vc = segue.destination as! LocationListViewController
            vc.managedContext = managedContext.parent  // we always save in the locationList but not necessarily in this TaskEdit/NewTask 
            vc.delegate = self 
        }
    }
}

extension TaskEditTableViewController: TaskDetailViewDelegate {
    func taskSelected(task: Task?, managedContext: NSManagedObjectContext) {
        self.task = task
        locationInChildCtx = task?.location
        self.managedContext = managedContext
    }
    
    func addTask(managedContext: NSManagedObjectContext) {
        locationInChildCtx = nil
        self.managedContext = managedContext
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

// MARK: - TextViewDelegate 

extension TaskEditTableViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.view.endEditing(true)
            return false
        }
        return true
    }
}

