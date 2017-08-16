//
//  Task+CoreDataClass.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

@objc(Task)
public class Task: NSManagedObject {

    func setDefaultsForNewTask() {
        self.completed = false
        self.category = TaskCategory.others
        
    }
    
}

extension Task {
    var descriptions: String {
        return "\(name!) Priority: \(priority)  Ranking: \(ranking)"
    }
}
