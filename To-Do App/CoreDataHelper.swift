//
//  CoreDataHelper.swift
//  iLocationAnnotation
//
//  Created by Wismin Effendi on 8/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import os.log
import CoreData
import CloudKit

public class CoreDataHelper {
        
    public static let sharedInstance = CoreDataHelper()
    
    private init() {}
    
    public func insertOrUpdateManagedObject(using ckRecord: CKRecord, managedObjectContext: NSManagedObjectContext) {
        switch ckRecord.recordType {
        case EntityName.LocationAnnotation:
            if let locationIdentifier = ckRecord[ckLocationAnnotation.identifier] as? String,
                let locationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: locationIdentifier, moc: managedObjectContext) {
                locationAnnotation.update(using: ckRecord)
            } else {
                let _ = LocationAnnotation.init(using: ckRecord, context: managedObjectContext)
            }
        case EntityName.Task:
            if let identifier = ckRecord[ckTask.identifier] as? String,
                let task = CoreDataUtil.getTask(identifier: identifier, moc: managedObjectContext) {
                    print("yes, we found the record...")
                    task.update(using: ckRecord)
            } else{
                let _ = Task.init(using: ckRecord, managedObjectContext: managedObjectContext)
            }
        default: fatalError("We got unexpected type: \(ckRecord.recordType)")
        }
    }
    
    public func splitIntoComponents(recordName: String) -> (entityName: String, identifier: String) {
        guard let dotIndex = recordName.characters.index(of: ".") else {
            fatalError("ERROR - RecordID.recordName should contain entity prefix")
        }
        let entityName = recordName.substring(to: dotIndex)
        let indexAfterDot = recordName.index(dotIndex, offsetBy: 1)
        let identifier = recordName.substring(from: indexAfterDot)
        return (entityName: entityName, identifier: identifier)
    }
    
    public func deleteManagedObject(using ckRecordID: CKRecordID, managedObjectContext: NSManagedObjectContext) {
        let (entityName, identifier) = splitIntoComponents(recordName: ckRecordID.recordName)
        switch entityName {
        case EntityName.LocationAnnotation:
            CoreDataUtil.deleteLocationAnnotation(identifier: identifier, moc: managedObjectContext)
        case EntityName.Task:
            CoreDataUtil.deleteTask(identifier: identifier, moc: managedObjectContext)
        default:
            fatalError("Unexpected entityName: \(entityName)")
        }
    }
    
    public func ckReferenceOf(locationAnnotation: LocationAnnotation) -> CKReference {
        let recordID = locationAnnotation.getCKRecordID()
        return CKReference(recordID: recordID, action: .deleteSelf)
    }
    
    public func coreDataLocationAnnotationFrom(ckReference: CKReference, managedObjectContext: NSManagedObjectContext) -> LocationAnnotation {
        let ckRecordID = ckReference.recordID
        let (entityName, identifier) = splitIntoComponents(recordName: ckRecordID.recordName)
        guard entityName == EntityName.LocationAnnotation else { fatalError("This parent ref should be LocationAnnotation") }
        guard let locationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: identifier, moc: managedObjectContext) else {
            fatalError("Could not find locationAnnotation for \(identifier) while searching reference record.")
        }
        return locationAnnotation
    }
    
    // MARK: - Helper to upload new/update to CloudKit
    // including deletion
    
    public func getRecordIDsForDeletion(managedObjectContext: NSManagedObjectContext) -> [CKRecordID]? {
        // gather the recordIDs for deletion
        let deletedLocationAnnotations = CoreDataUtil.getLocationAnnotationsOf(predicate: Predicates.DeletedLocationAnnotation, moc: managedObjectContext)
        let deletedLocationAnnotationRecordIDs = deletedLocationAnnotations.map { $0.getCKRecordID() }
        let deletedTasks = CoreDataUtil.getTasks(predicate: Predicates.DeletedTask, moc: managedObjectContext)
        let deletedTaskRecordIDs = deletedTasks.map { $0.getCKRecordID() }
        
        let deletedRecords = deletedLocationAnnotationRecordIDs + deletedTaskRecordIDs
        
        return deletedRecords == [] ? nil : deletedRecords
    }
    
    public func postSuccessfulDeletionOnCloudKit(managedObjectContext: NSManagedObjectContext) {
        // here we delete from core data permanently
        CoreDataUtil.batchDeleteTaskPendingDeletion(managedObjectContext: managedObjectContext)
        CoreDataUtil.batchDeleteLocationAnnotationPendingDeletion(managedObjectContext: managedObjectContext)
    }
    
    public func getRecordsToModify(managedObjectContext: NSManagedObjectContext) -> [CKRecord]? {
        // update / modify
        // Create New Records
        let newLocationAnnotations = CoreDataUtil.getLocationAnnotationsOf(predicate: Predicates.NewLocationAnnotation, moc: managedObjectContext)
        let newLocationAnnotationRecords = newLocationAnnotations.map { $0.managedObjectToNewCKRecord() }
        let newTasks = CoreDataUtil.getTasks(predicate: Predicates.NewTask, moc: managedObjectContext)
        let newTaskRecords = newTasks.map { $0.managedObjectToNewCKRecord() }
        
        // Update existing Records
        let updatedLocationAnnotations = CoreDataUtil.getLocationAnnotationsOf(predicate: Predicates.UpdatedLocationAnnotation, moc: managedObjectContext)
        let updatedLocationAnnotationRecords = updatedLocationAnnotations.map { $0.managedObjectToUpdatedCKRecord() }
        let updatedTasks = CoreDataUtil.getTasks(predicate: Predicates.UpdatedTask, moc: managedObjectContext)
        let updatedTaskRecords = updatedTasks.map { $0.managedObjectToUpdatedCKRecord() }
        
        let newAndUpdatedRecords = newLocationAnnotationRecords + newTaskRecords +
                                    updatedLocationAnnotationRecords + updatedTaskRecords
        return newAndUpdatedRecords == [] ? nil : newAndUpdatedRecords
    }
    
    public func postSuccessfyModifyOnCloudKit(modifiedCKRecords: [CKRecord], managedObjectContext: NSManagedObjectContext) {
        //  update metadata and modify needsUpload flag
        let modifiedLocationAnnotationCKRecords = modifiedCKRecords.filter { $0.recordType == RecordType.LocationAnnotation.rawValue }
        let modifiedTaskCKRecords = modifiedCKRecords.filter { $0.recordType == RecordType.Task.rawValue }
        
        CoreDataUtil.updateLocationAnnotationCKMetadata(from: modifiedLocationAnnotationCKRecords, managedObjectContext: managedObjectContext)
        CoreDataUtil.updateTaskCKMetadata(from: modifiedTaskCKRecords, managedObjectContext: managedObjectContext)
    }
}
