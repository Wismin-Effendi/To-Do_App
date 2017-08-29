//
//  LocationAnnotation+CoreDataClass.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit 

@objc(LocationAnnotation)
public class LocationAnnotation: NSManagedObject, CloudKitConvertible {

    public func setDefaultsForLocalCreate() {
        self.localUpdate = NSDate()
        self.needsUpload = true
        self.pendingDeletion = false
        self.archived = false 
    }
}

extension LocationAnnotation {
    
    public convenience init(using cloudKitRecord: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        update(using: cloudKitRecord)
    }
    
    public func setDefaultValuesForLocalCreation() {
        self.localUpdate = NSDate()
        self.pendingDeletion = false
        self.needsUpload = true
    }
    
    public func setForLocalDeletion() {
        self.needsUpload = true
        self.pendingDeletion = true
        self.localUpdate = NSDate()
    }
    
    public func update(using cloudKitRecord: CKRecord) {
        self.title = cloudKitRecord[ckLocationAnnotation.title] as! String
        self.needsUpload = false
        self.pendingDeletion = false
        self.archived = cloudKitRecord[ckLocationAnnotation.archived] as! Bool
        self.identifier = cloudKitRecord[ckLocationAnnotation.identifier] as! String
        self.localUpdate = (cloudKitRecord[ckLocationAnnotation.localUpdate] as! NSDate)
        self.annotation = cloudKitRecord[ckLocationAnnotation.annotation] as! LocationAnnotation
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: cloudKitRecord)
     
        try! self.managedObjectContext?.save()
    }
    
    public func updateCKMetadata(from ckRecord: CKRecord) {
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: ckRecord)
        self.needsUpload = false
        
        try! self.managedObjectContext?.save()
    }
    
    public func managedObjectToNewCKRecord() -> CKRecord {
        guard ckMetadata == nil else {
            fatalError("CKMetaData exist, this should is not a new CKRecord")
        }
        
        let recordZoneID = CKRecordZoneID(zoneName: CloudKitZone.Todododo.rawValue, ownerName: CKCurrentUserDefaultName)
        let recordName = EntityName.LocationAnnotation + "." + self.identifier
        let recordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        let ckRecord = CKRecord(recordType: RecordType.LocationAnnotation.rawValue, recordID: recordID)
        ckRecord[ckLocationAnnotation.title] = self.title as CKRecordValue
        ckRecord[ckLocationAnnotation.identifier] = self.identifier as CKRecordValue
        ckRecord[ckLocationAnnotation.localUpdate] = self.localUpdate
        ckRecord[ckLocationAnnotation.annotation] = self.annotation as? CKRecordValue
        
        return ckRecord
    }
    
    public func managedObjectToUpdatedCKRecord() -> CKRecord {
        guard let ckMetadata = self.ckMetadata else {
            fatalError("CKMetaData is required to update CKRecord")
        }
        
        let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
        ckRecord[ckLocationAnnotation.title] = self.title as CKRecordValue
        ckRecord[ckLocationAnnotation.identifier] = self.identifier as CKRecordValue
        ckRecord[ckLocationAnnotation.localUpdate] = self.localUpdate
        ckRecord[ckLocationAnnotation.annotation] = self.annotation as? CKRecordValue

        return ckRecord
    }
    
    public func getCKRecordID() -> CKRecordID {
        let ckRecordID: CKRecordID
        if let ckMetadata = self.ckMetadata  {
            let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
            ckRecordID = ckRecord.recordID
        } else {
            let recordZoneID = CKRecordZoneID(zoneName: CloudKitZone.Todododo.rawValue, ownerName: CKCurrentUserDefaultName)
            let recordName = EntityName.LocationAnnotation + "." + self.identifier
            ckRecordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        }
        return ckRecordID
    }
}
