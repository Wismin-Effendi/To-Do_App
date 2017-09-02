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
    var completedTasks = [String]() // save the task identifier
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        visualEffectView.effect = UIVibrancyEffect.widgetPrimary()
        statusButton.setImage(#imageLiteral(resourceName: "checked"), for: .normal)
        statusButton.isEnabled = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    @IBAction func taskCompleted(_ sender: UIButton) {
        completed = true
        // Instead of saving to CoreData directly, save the changes to UserDefaults in app group.
        guard let userDefault = UserDefaults(suiteName: UserDefaults.appGroup) else { return }
        let currentCompletedTasks = userDefault.array(forKey: UserDefaults.Keys.completedInTodayExtension) as! [String]?
        completedTasks = (currentCompletedTasks != nil) ? currentCompletedTasks! : completedTasks
        completedTasks.append(task.identifier)
        userDefault.set(completedTasks, forKey: UserDefaults.Keys.completedInTodayExtension)
        userDefault.synchronize()
        statusButton.setImage(#imageLiteral(resourceName: "checked-custom"), for: .normal)
    }
    
}
