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

class TaskEditTableViewController: UITableViewController {

    enum TextFieldTag: Int {
        case taskName = 100
        case category
        case dueDate
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var taskNameTexField: UITextField!
    @IBOutlet weak var priorityTextField: UITextField!
    @IBOutlet weak var dueDateTextField: UITextField!
    
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
    var priorityMaxRankingDict: [Int:Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Maybe don't need anymore since we use static table view
        registerForKeyboardNotification()  // to scroll content up when show keyboard
        datePicker.isHidden = true
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
            if let taskDueDate = task?.dueDate as Date? {
                dueDate = taskDueDate
                if dueDate != nil { datePicker.date = dueDate! }
            }
        }
        
        // Enable the Save button only if the text field has a valid Task name
        updateSaveButtonState()
        
        // Test to print out max ranking by priority
        if let maxRankByPriority = Util.getMaxRankingGroupByPriority(moc: managedContext) {
            print("This is maxRankByPriority output: ")
            print(maxRankByPriority)
        }
        // actual assignemnt
        priorityMaxRankingDict = Util.getMaxRankingGroupByPriority(moc: managedContext)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateSplitViewSetting()
    }
    
    
    private func updateSplitViewSetting() {
        isSplitView = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular
        cancelButton.title = isSplitView ? "Clear All" : "Cancel"
        // also the cancel and save button has dependency on isSplitView value.
    }
    
    private func clearAllFields() {
        taskNameTexField.text = ""
        dueDateTextField.text = ""
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
        let priority = Int16(priorityTextField.text!) ?? 1
        
        // Set the task to be passed to TaskTableViewController after the unwind segue
        do {
            if task == nil {  // add new Task
                task = Task(context: managedContext)
                // assign new Ranking for new Task
                if let priorityMaxRankingDict = priorityMaxRankingDict,
                    let maxRanking = priorityMaxRankingDict[Int(priority)] {
                    let nextRanking = maxRanking + 1
                    task!.ranking = Int32(nextRanking)
                } else {
                    task!.ranking = 0  // default first value for ranking
                }
            }
            task!.name = name
            task!.completed = false
            task!.priority = priority
            task!.dueDate = dueDate as NSDate?
            
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
    
    private func registerForKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    func keyboardDidShow(_ notification: Notification) {
        if let info = notification.userInfo,
            let kbSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size {
            
            let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
            UIView.animate(withDuration: 0.5) {[unowned self] in
                self.scrollView.contentInset = contentInsets
                self.scrollView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        UIView.animate(withDuration: 0.33) { [unowned self] in
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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

