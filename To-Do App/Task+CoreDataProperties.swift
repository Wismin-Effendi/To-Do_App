//
//  Task+CoreDataProperties.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/18/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var location: NSObject?
    @NSManaged public var completed: Bool
    @NSManaged public var dueDate: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var priority: Int16
    @NSManaged public var ranking: Int32

}
