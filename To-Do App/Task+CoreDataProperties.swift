//
//  Task+CoreDataProperties.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/29/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var category: String?
    @NSManaged public var dueDate: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var ranking: Int32
    @NSManaged public var priority: Int16

}
