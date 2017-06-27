//
//  TaskViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import os.log

class TaskViewController: UIViewController {
    
    
    @IBOutlet weak var taskNameTexField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var task: Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Handle the text fields's user input through delegate callbacks.
        taskNameTexField.delegate = self
        
        // Set up views if editing an existing Task
        if let task = task {
            navigationItem.title = task.name
            taskNameTexField.text = task.name
            categoryTextField.text = task.category 
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

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let button = sender as? UIBarButtonItem, button == saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        let name = taskNameTexField.text ?? ""
        let category = categoryTextField.text ?? ""
        // Set the task to be passed to TaskTableViewController after the unwind segue 
        task = Task(name: name, category: category)
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
    

}
