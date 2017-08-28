//
//  Task+CoreDataProperties.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var archived: Bool
    @NSManaged public var completed: Bool
    @NSManaged public var completionDate: NSDate?
    @NSManaged public var dueDate: NSDate
    @NSManaged public var identifier: String
    @NSManaged public var localUpdate: NSDate
    @NSManaged public var name: String
    @NSManaged public var needsUpload: Bool
    @NSManaged public var pendingDeletion: Bool
    @NSManaged public var reminder: Bool
    @NSManaged public var reminderDate: NSDate?
    @NSManaged public var location: LocationAnnotation?

}
