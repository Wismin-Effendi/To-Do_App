//
//  Task+CoreDataProperties.swift
//  Todododo
//
//  Created by Wismin Effendi on 9/5/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var archived: Bool
    @NSManaged public var ckMetadata: NSObject?
    @NSManaged public var completed: Bool
    @NSManaged public var completionDate: NSDate?
    @NSManaged public var dueDate: NSDate
    @NSManaged public var identifier: String
    @NSManaged public var localUpdate: NSDate
    @NSManaged public var needsUpload: Bool
    @NSManaged public var pendingDeletion: Bool
    @NSManaged public var reminder: Bool
    @NSManaged public var reminderDate: NSDate?
    @NSManaged public var title: String
    @NSManaged public var notes: String
    @NSManaged public var location: LocationAnnotation?

}
