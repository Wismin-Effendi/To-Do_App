//
//  CoreDateUtil.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/23/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import os.log

public class CoreDataUtil {
    
    public static func locationAnnotation(by identifier: String, managedContext: NSManagedObjectContext) -> LocationAnnotation? {
        
        var result: LocationAnnotation? = nil
        managedContext.performAndWait {
            let fetchRequest: NSFetchRequest<LocationAnnotation> = LocationAnnotation.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(LocationAnnotation.identifier), identifier)
            fetchRequest.fetchLimit = 1
            do {
                let results = try managedContext.fetch(fetchRequest)
                result = results.first
            } catch {
                fatalError("Failed to fetch location annotation from core Data. \(error.localizedDescription)")
            }
        }
        return result
    }
    
    public static func cloneAsActiveTask(task: Task, managedContext: NSManagedObjectContext) {
        let newTask = Task(context: managedContext)
        newTask.setDefaultsForLocalCreate()
        newTask.title = task.title
        newTask.location = task.location
    }
    
    public static func getIDsLocationAnnotationPendingDeletion(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "pendingDeletion == YES")
        let entity = LocationAnnotation()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsLocationAnnotationNeedsUpload(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "needsUpload == YES")
        let entity = LocationAnnotation()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsTaskPendingDeletion(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "pendingDeletion == YES")
        let entity = Task()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsTaskNeedsUpload(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "needsUpload == YES")
        let entity = Task()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsOfEntities<E>(entity: E, predicate: NSPredicate, moc: NSManagedObjectContext) -> [String] where E: NSManagedObject, E: CloudKitConvertible {
        var entityIDs = [String]()
        moc.performAndWait {
            let entityFetch: NSFetchRequest<NSFetchRequestResult> = E.fetchRequest()
            entityFetch.predicate = predicate
            do {
                let results = (try moc.fetch(entityFetch)) as! [E]
                entityIDs = results.map { $0.identifier }
            } catch let error as NSError {
                fatalError("Failed to retrieved all Identifier of Task for \(predicate) \(error.localizedDescription)")
            }
        }
        return entityIDs
    }
    
    public static func getALocationAnnotationOf(locationIdentifier: String, moc: NSManagedObjectContext) -> LocationAnnotation? {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(LocationAnnotation.identifier), locationIdentifier)
        return getLocationAnnotationsOf(predicate: predicate, moc: moc).first
    }
    
    public static func getALocationAnnotationOf(locationName: String, moc: NSManagedObjectContext) -> LocationAnnotation? {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(LocationAnnotation.title), locationName)
        return getLocationAnnotationsOf(predicate: predicate, moc: moc).first
    }
    
    public static func getLocationAnnotationsOf(predicate: NSPredicate, moc: NSManagedObjectContext) -> [LocationAnnotation] {
        var results = [LocationAnnotation]()
        moc.performAndWait {
            let locationAnnotationFetch: NSFetchRequest<LocationAnnotation> = LocationAnnotation.fetchRequest()
            locationAnnotationFetch.predicate = predicate
            
            do {
                results = try moc.fetch(locationAnnotationFetch)
            } catch let error as NSError {
                fatalError("Failed to fetch shopping lists. \(error.localizedDescription)")
            }
        }
        return results
    }
    
    
    
    public static func getTaskCount(predicate: NSPredicate, moc: NSManagedObjectContext) -> Int {
        return getTasks(predicate: predicate, moc: moc).count
    }
    
    public static func getTask(identifier: String, moc: NSManagedObjectContext) -> Task? {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(Task.identifier), identifier)
        return getTasks(predicate: predicate, moc: moc).first
    }
    
    public static func getTasks(predicate: NSPredicate, moc: NSManagedObjectContext) -> [Task] {
        var results = [Task]()
        moc.performAndWait {
            let taskFetch: NSFetchRequest<Task> = Task.fetchRequest()
            taskFetch.predicate = predicate
            
            do {
                results = try moc.fetch(taskFetch)
            } catch let error as NSError {
                fatalError("Failed to fetch grocery items by identifier. \(error.localizedDescription)")
            }
        }
        return results
    }
    
    public static func getTasks(identifiers: [String], moc: NSManagedObjectContext) -> [Task] {
        let predicate = NSPredicate(format: "%K IN %@", #keyPath(Task.identifier), identifiers)
        return getTasks(predicate: predicate, moc: moc)
    }
    
    public static func updateTaskCompletionFor(identifiers: [String], moc: NSManagedObjectContext) {
        moc.perform {
            let tasks = getTasks(identifiers: identifiers, moc: moc)
            for task in tasks {
                task.setDefaultsForCompletion()
                print("Task that got updated: \(task)")
                os_log("We are supposed to be here....")
            }
            try! moc.save()
            DispatchQueue.main.async {
                try! moc.parent?.save()
            }
        }
    }
    
    public static func deleteLocationAnnotation(title: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(LocationAnnotation.title), title)
        deleteLocationAnnotation(predicate: predicate, moc: moc)
    }
    
    public static func deleteLocationAnnotation(identifier: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(LocationAnnotation.identifier), identifier)
        deleteLocationAnnotation(predicate: predicate, moc: moc)
    }
    
    
    public static func deleteLocationAnnotation(predicate: NSPredicate, moc: NSManagedObjectContext) {
        moc.perform {
            let locationAnnotationFetch: NSFetchRequest<LocationAnnotation> = LocationAnnotation.fetchRequest()
            locationAnnotationFetch.predicate = predicate
            do {
                let results = try moc.fetch(locationAnnotationFetch)
                for result in results {
                    moc.delete(result)
                    try moc.save()
                }
            } catch let error as NSError {
                fatalError("Failed to delete from locationAnnotation. \(error.localizedDescription)")
            }
        }
    }
    
    public static func deleteTask(title: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(Task.title), title)
        deleteTask(predicate: predicate, moc: moc)
    }
    
    public static func deleteTask(identifier: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(Task.identifier), identifier)
        deleteTask(predicate: predicate, moc: moc)
    }
    
    public static func deleteAllTasks(moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        deleteTask(predicate: predicate, moc: moc)
    }
    
    public static func deleteTask(predicate: NSPredicate, moc: NSManagedObjectContext) {
        moc.perform {
            let taskFetch: NSFetchRequest<Task> = Task.fetchRequest()
            taskFetch.predicate = predicate
            do {
                let results = try moc.fetch(taskFetch)
                for result in results {
                    if let locationAnnotation = result.location {
                        locationAnnotation.removeFromTasks(result)
                    }
                    moc.delete(result)
                    try moc.save()
                }
            } catch let error as NSError {
                fatalError("Failed to delete from task. \(error.localizedDescription)")
            }
        }
    }
    
    public static func updateLocationAnnotationCKMetadata(from cloudKitRecords: [CKRecord], managedObjectContext: NSManagedObjectContext) {
        for ckRecord in cloudKitRecords {
            let identifier: String = ckRecord[ckLocationAnnotation.identifier] as! String
            if let locationAnnotation = getALocationAnnotationOf(locationIdentifier: identifier, moc: managedObjectContext) {
                locationAnnotation.updateCKMetadata(from: ckRecord)
            } else {
                let title = ckRecord[ckLocationAnnotation.title] as! String
                fatalError("Can't find record to update metadata for \(title)")
            }
        }
    }
    
    public static func updateTaskCKMetadata(from cloudKitRecords: [CKRecord], managedObjectContext: NSManagedObjectContext) {
        for ckRecord in cloudKitRecords {
            let identifier: String = ckRecord[ckTask.identifier] as! String
            if let task = getTask(identifier: identifier, moc: managedObjectContext) {
                task.updateCKMetadata(from: ckRecord)
            } else {
                let title = ckRecord[ckTask.title] as! String
                fatalError("Can't find record to update metadata for \(title)")
            }
        }
    }
    
    public static func batchDeleteLocationAnnotationPendingDeletion(managedObjectContext: NSManagedObjectContext) {
        let locationAnnotationFetch: NSFetchRequest<NSFetchRequestResult> = LocationAnnotation.fetchRequest()
        locationAnnotationFetch.predicate = Predicates.DeletedLocationAnnotation
        batchDeleteManagedObject(fetchRequest: locationAnnotationFetch, managedObjectContext: managedObjectContext)
    }
    
    public static func batchDeleteTaskPendingDeletion(managedObjectContext: NSManagedObjectContext) {
        let taskFetch: NSFetchRequest<NSFetchRequestResult> = Task.fetchRequest()
        taskFetch.predicate = Predicates.DeletedTask
        batchDeleteManagedObject(fetchRequest: taskFetch, managedObjectContext: managedObjectContext)
    }
    
    public static func batchDeleteManagedObject(fetchRequest: NSFetchRequest<NSFetchRequestResult>, managedObjectContext: NSManagedObjectContext) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeStatusOnly
        try! managedObjectContext.execute(batchDeleteRequest)
    }
    
    public static func createOneSampleLocationAnnotation(title: String, moc: NSManagedObjectContext) {
        moc.perform {
            let item = LocationAnnotation(context: moc)
            item.title = title
            item.identifier = UUID().uuidString
            do {
                try moc.save()
            } catch let error as NSError {
                fatalError("Failed to create sample LocationAnnotation item. \(error.localizedDescription)")
            }
        }
    }

     
    /// MARK:  Get records count
    
    public static func getTasksCount(title: String, moc: NSManagedObjectContext) -> Int {
        let keyPathExp = NSExpression(forKeyPath: #keyPath(Task.title))
        let predicate = NSPredicate(format: "%K == %@", #keyPath(Task.title), title)
        let type = Task()
        return getEntityItemsCount(keyPathExp: keyPathExp, predicate: predicate, type: type, moc: moc)
    }
    
    // A proper way to count given that we don't fetch items to memory just to count them.
    public static func getEntityItemsCount<T: NSManagedObject>(keyPathExp: NSExpression, predicate: NSPredicate,
                                           type: T, moc: NSManagedObjectContext) -> Int {
        
        let expression = NSExpression(forFunction: "count:", arguments: [keyPathExp])
        
        let countDesc = NSExpressionDescription()
        countDesc.expression = expression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        
        let currentItemFetch: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        currentItemFetch.predicate = predicate
        currentItemFetch.returnsObjectsAsFaults = false
        currentItemFetch.propertiesToFetch = [countDesc]
        currentItemFetch.resultType = .countResultType
        
        do {
            let countResults = try moc.fetch(currentItemFetch)
            return countResults.first as! Int
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
    
    public static func getTaskIdentifierFromTitle(title: String, moc: NSManagedObjectContext) -> String? {
        let taskFetch: NSFetchRequest<Task> = Task.fetchRequest()
        taskFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(Task.title), title)
        do {
            let results = try moc.fetch(taskFetch)
            guard let first = results.first else { return nil }
            return first.identifier
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
    
    public static func createNewLocationAnnotationRecord(from cloudKitRecord: CKRecord, moc: NSManagedObjectContext,
                                                   completion: @escaping (NSError?) -> ()) {
        moc.perform {
            _ = LocationAnnotation(using: cloudKitRecord, context: moc)
            do {
                try moc.save()
            } catch let error as NSError {
                os_log("Failed to create shopping list record. %@", error.localizedDescription)
                completion(error)
            }
            completion(nil)
        }
    }
    
    public static func updateCoreDataLocationAnnotationRecord(_ locationAnnotation: LocationAnnotation, using cloudKitRecord: CKRecord,
                                                        moc: NSManagedObjectContext, completion: @escaping (NSError?) -> ()) {
        moc.perform {
            locationAnnotation.update(using: cloudKitRecord)
            do {
                try moc.save()
            } catch let error as NSError {
                os_log("Failed to update shopping list record. %@", error.localizedDescription)
                completion(error)
            }
            completion(nil)
        }
    }
    
    
    public static func updateCoreDataTaskRecord(_ task: Task, using cloudKitRecord: CKRecord,
                                                       moc: NSManagedObjectContext, completion: @escaping (NSError?) -> ()) {
        moc.perform {
            task.update(using: cloudKitRecord)
            do {
                try moc.save()
            } catch let error as NSError {
                os_log("Failed to update grocery item record. %@", error.localizedDescription)
                completion(error)
            }
            completion(nil)
        }
    }
    
    public static func getPreviousServerChangeToken(moc: NSManagedObjectContext) -> CKServerChangeToken?  {
        let changeTokenFetch: NSFetchRequest<ChangeToken> = ChangeToken.fetchRequest()
        changeTokenFetch.fetchLimit = 1
        do {
            let results = try moc.fetch(changeTokenFetch)
            return results.first?.previousServerChangeToken as? CKServerChangeToken
        } catch let error as NSError {
            fatalError("Failed to retrieve from ChangeToken. \(error.localizedDescription)")
        }
    }
    
    public static func deletePreviousServerChangeToken(moc: NSManagedObjectContext) {
        moc.perform {
            let changeTokenFetch: NSFetchRequest<ChangeToken> = ChangeToken.fetchRequest()
            changeTokenFetch.fetchLimit = 1
            do {
                let results = try moc.fetch(changeTokenFetch)
                if results.count == 0 { return }
                else if results.count == 1 {
                    let changeToken = results.first!
                    moc.delete(changeToken)
                    try moc.save()
                } else {
                    fatalError("ChangeToken should only has one entry")
                }
            } catch let error as NSError {
                fatalError("Failed to retrieve from ChangeToken. \(error.localizedDescription)")
            }
        }
    }
    
    public static func setPreviousServerChangeToken(previousServerChangeToken: CKServerChangeToken, moc: NSManagedObjectContext) {
        moc.perform {
            let changeTokenFetch: NSFetchRequest<ChangeToken> = ChangeToken.fetchRequest()
            changeTokenFetch.fetchLimit = 1
            
            let changeToken: ChangeToken
            do {
                let results = try moc.fetch(changeTokenFetch)
                if results.count > 0 {
                    changeToken = results.first!
                    changeToken.previousServerChangeToken = previousServerChangeToken
                } else {
                    changeToken = ChangeToken(context: moc)
                    changeToken.previousServerChangeToken = previousServerChangeToken
                }
                try moc.save()
            } catch let error as NSError {
                fatalError("Failed to create from ChangeToken. \(error.localizedDescription)")
            }
        }
    }
}

