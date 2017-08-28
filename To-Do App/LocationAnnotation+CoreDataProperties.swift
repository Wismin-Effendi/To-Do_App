//
//  LocationAnnotation+CoreDataProperties.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension LocationAnnotation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationAnnotation> {
        return NSFetchRequest<LocationAnnotation>(entityName: "LocationAnnotation")
    }

    @NSManaged public var annotation: NSObject
    @NSManaged public var archived: Bool
    @NSManaged public var identifier: String
    @NSManaged public var localUpdate: NSDate
    @NSManaged public var needsUpload: Bool
    @NSManaged public var pendingDeletion: Bool
    @NSManaged public var title: String
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension LocationAnnotation {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}
