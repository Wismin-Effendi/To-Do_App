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
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    var task: Task! {
        didSet {
            title.text = task.title
            completed = task.completed
            statusButton.isEnabled = true
        }
    }
    
    var completed: Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        visualEffectView.effect = UIVibrancyEffect.widgetPrimary()
        statusButton.setImage(#imageLiteral(resourceName: "unchecked"), for: .normal)
        statusButton.isEnabled = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    @IBAction func taskCompleted(_ sender: UIButton) {
        completed = true
        task.completed = true
        do {
            if let managedContext = task.managedObjectContext,
                managedContext.hasChanges {
                try managedContext.save()
            }
        } catch {
            os_log("Error during save completed task in Widget: %@", error.localizedDescription)
        }
        statusButton.setImage(#imageLiteral(resourceName: "checked"), for: .normal)
    }
    
}
