//
//  WidgetTableViewCell.swift
//  Todododo
//
//  Created by Wismin Effendi on 8/31/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import os.log
import CoreData
import ToDoCoreDataCloudKit

class WidgetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var statusButton: UIButton!

    
    var task: Task! {
        didSet {
            title.text = task.title
            completed = task.completed
            statusButton.isEnabled = true
        }
    }
    
    var completed: Bool!
    var completedTasks = [String]() // save the task identifier
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        statusButton.setImage(#imageLiteral(resourceName: "checked"), for: .normal)
        statusButton.isEnabled = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    @IBAction func taskCompleted(_ sender: UIButton) {
        completed = true
        statusButton.setImage(#imageLiteral(resourceName: "checked-custom"), for: .normal)
        task.completed = true
        guard let managedContext = task.managedObjectContext else { return }
        do {
            try managedContext.save()
        } catch let error as NSError {
            fatalError("Error during core data save in Widget: \(error.localizedDescription)")
        }
    }
    
}
