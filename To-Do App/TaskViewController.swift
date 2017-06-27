//
//  TaskViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import os.log
import CoreData

class TaskViewController: UIViewController {
    
    enum TextFieldTag: Int {
        case taskName = 100
        case category
        case dueDate
    }
    
    
    @IBOutlet weak var taskNameTexField: UITextField!
    @IBOutlet weak var priorityTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var dueDateTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var taskStackView: UIStackView!
    @IBOutlet weak var categoryStackView: UIStackView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var showDatePicker: Bool = false {
        didSet {
            switch showDatePicker {
            case true:
                datePicker.isHidden = false
                taskStackView.isHidden = true
                categoryStackView.isHidden = true
            case false:
                datePicker.isHidden = true
                taskStackView.isHidden = false
                categoryStackView.isHidden = false
            }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showDatePicker = false
        priorityTextField.isEnabled = false 
        // Set tag on textField of interest only
        taskNameTexField.tag = TextFieldTag.taskName.rawValue
        dueDateTextField.tag = TextFieldTag.dueDate.rawValue
        // Handle the text fields's user input through delegate callbacks.
        taskNameTexField.delegate = self
        dueDateTextField.delegate = self
        
        // Set up views if editing an existing Task
        if let task = task {
            navigationItem.title = task.name
            taskNameTexField.text = task.name
            priorityTextField.text = "\(task.priority)"
            categoryTextField.text = task.category
            if let taskDueDate = task.dueDate as Date? {
                dueDate = taskDueDate
            }
        }
        
        // Enable the Save button only if the text field has a valid Task name 
        updateSaveButtonState()
    }

    // MARK: Action 
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), controller needs to be dismissed in two different ways
        let isPresentingInAddTaskMode = presentingViewController is UINavigationController
        if isPresentingInAddTaskMode {
            // Add Task mode
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController {
            // editing Task mode
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The TaskViewController is not inside a navigation controller.")
        }
    }

    @IBAction func datePickerValueChange(_ sender: UIDatePicker) {
        dueDate = sender.date
    }

    fileprivate func setDueDateTextField(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        dueDateTextField.text = dateFormatter.string(from: date)
    }
    
    @IBAction func priorityStepperValueChange(_ sender: UIStepper) {
        priorityTextField.text = Int(sender.value).description
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let button = sender as? UIBarButtonItem, button == saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        let name = taskNameTexField.text ?? ""
        let priority = Int16(priorityTextField.text!) ?? 1
        let category = categoryTextField.text ?? ""
        
        // Set the task to be passed to TaskTableViewController after the unwind segue
        do {
            if task == nil {  // add new Task 
                task = Task(context: managedContext)
            }
            task?.name = name
            task?.priority = priority
            task?.category = category
            task?.dueDate = dueDate as NSDate?
            
            try managedContext.save()
        } catch {
            print(error)
        }

    }

    
    // MARK: Private Methods
    fileprivate func updateSaveButtonState() {
        // Disable the Save button if the text field is empty
        let text = taskNameTexField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }

}

// MARK: UITextFieldDelegate
extension TaskViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing 
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Special treatment for dueDateTextField only
        guard textField.tag == TextFieldTag.dueDate.rawValue else { return true }
        // dueDate use datePicker instead
        showDatePicker = !showDatePicker
        dueDate = datePicker.date
        return false
    }
    
    
    
}
