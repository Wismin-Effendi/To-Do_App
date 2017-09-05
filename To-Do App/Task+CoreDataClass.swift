//
//  Task+CoreDataClass.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/18/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import SwiftDate

@objc(Task)
public class Task: NSManagedObject, CloudKitConvertible {
    func setDefaultsForNewTask() {
        self.completed = false
    }
    
    public func setDefaultsForLocalCreate() {
        self.localUpdate = NSDate()
        self.completed = false
        self.completionDate = NSDate.init(timeIntervalSinceReferenceDate: 0)
        self.needsUpload = true
        self.pendingDeletion = false
        self.identifier = UUID().uuidString
        self.archived = false
        let defaultDeltaInHours: Int = Int( UserDefaults.standard.double(forKey: UserDefaults.Keys.dueHoursFromNow) )
        self.dueDate = (Date() + (defaultDeltaInHours).hours) as NSDate
        self.reminder = false
        self.reminderDate = dueDate
        self.title = NSLocalizedString("Rename this new Task", comment:"")
    }
    
    public func setDefaultsForLocalChange() {
        self.localUpdate = NSDate()
        self.needsUpload = true 
        self.pendingDeletion = false 
    }

    public func setDefaultsForCompletion() {
        setDefaultsForLocalChange()
        self.completed = true 
        self.completionDate = NSDate()
    }
    
    public func setForLocalDeletion() {
        self.needsUpload = false 
        self.pendingDeletion = true 
        self.localUpdate = NSDate()
    }

    public func setDefaultsForRemoteModify() {
        self.needsUpload = false 
        self.pendingDeletion = false 
        self.archived = false 
        self.localUpdate = NSDate() 
    }
    
    private func isDateIn(_ referenceDate: Date, component: Calendar.Component, input date: Date) -> Bool {
        return date.isIn(date: referenceDate, granularity: component)
    }
    
    var dueDateType: String {
        let now = Date()
        let dueDate = self.dueDate as Date
        
        if isDateIn(now, component: .day, input: dueDate) {
            return NSLocalizedString(TimeOrder.today.rawValue, comment: "")
        } else if dueDate > now {
            return futureDateType(dueDate)
        } else {
            return pastDateType(dueDate)
        }
    }
    
    var completionDateType: String {
        let now = Date()
        let completionDate = self.completionDate! as Date
        
        if isDateIn(now, component: .day, input: completionDate) {
            return NSLocalizedString(TimeOrder.today.rawValue, comment:"")
        } else if completionDate > now {
            return futureDateType(completionDate)
        } else {
            return pastDateType(completionDate)
        }
    }
    
    private func futureDateType(_ inputDate: Date) -> String {
        let now = Date()
        let tomorrow = now + 1.day
        let twoDaysFromNow = tomorrow + 1.day
        let nextWeek = now + 1.week
        let twoWeeksFromNow = nextWeek + 1.week
        
        if isDateIn(tomorrow, component: .day, input: inputDate) {
            return NSLocalizedString(TimeOrder.tomorrow.rawValue, comment:"")
        } else if isDateIn(twoDaysFromNow, component: .day, input: inputDate) {
            return NSLocalizedString(TimeOrder.twoDaysFromNow.rawValue, comment:"")
        } else if isDateIn(now, component: .weekOfYear, input: inputDate) {
            return NSLocalizedString(TimeOrder.futureDaysInThisWeek.rawValue, comment:"")
        } else if isDateIn(nextWeek, component: .weekOfYear, input: inputDate) {
            return NSLocalizedString(TimeOrder.nextWeek.rawValue, comment:"")
        } else if isDateIn(twoWeeksFromNow, component: .weekOfYear, input: inputDate) {
            return NSLocalizedString(TimeOrder.twoWeeksFromNow.rawValue, comment:"")
        } else {
            return NSLocalizedString(TimeOrder.sometimeInTheFuture.rawValue, comment:"")
        }
    }
    
    private func pastDateType(_ inputDate: Date) -> String {
        let now = Date()
        let yesterday = now - 1.day
        let twoDaysAgo = yesterday - 1.day
        let lastWeek = now - 1.week
        let twoWeeksAgo = lastWeek - 1.week
        
        if isDateIn(yesterday, component: .day, input: inputDate) {
            return NSLocalizedString(TimeOrder.yesterday.rawValue, comment:"")
        } else if isDateIn(twoDaysAgo, component: .day, input: inputDate) {
            return NSLocalizedString(TimeOrder.twoDaysAgo.rawValue, comment:"")
        } else if isDateIn(now, component: .weekOfYear, input: inputDate) {
            return NSLocalizedString(TimeOrder.previousDaysInThisWeek.rawValue, comment:"")
        } else if isDateIn(lastWeek, component: .weekOfYear, input: inputDate) {
            return NSLocalizedString(TimeOrder.lastWeek.rawValue, comment:"")
        } else if isDateIn(twoWeeksAgo, component: .weekOfYear, input: inputDate) {
            return NSLocalizedString(TimeOrder.twoWeeksAgo.rawValue, comment:"")
        } else {
            return NSLocalizedString(TimeOrder.sometimeInThePast.rawValue, comment:"")
        }
    }
    
}


extension Task {

    public convenience init(using cloudKitRecord: CKRecord, managedObjectContext: NSManagedObjectContext) {
        self.init(context: managedObjectContext)
        self.setDefaultsForRemoteModify()
        self.identifier = cloudKitRecord[ckTask.identifier] as! String 
        let ckReference = cloudKitRecord[ckTask.location] as! CKReference
        self.location = CoreDataHelper.sharedInstance.coreDataLocationAnnotationFrom(ckReference: ckReference, managedObjectContext: managedObjectContext)
        update(using: cloudKitRecord)
    }
    
    public func update(using cloudKitRecord: CKRecord) {
        self.archived = cloudKitRecord[ckTask.archived] as! Bool
        self.dueDate = (cloudKitRecord[ckTask.dueDate] as! NSDate)
        self.completed = cloudKitRecord[ckTask.completed] as! Bool
        self.completionDate = (cloudKitRecord[ckTask.completionDate] as! NSDate)
        self.reminder = cloudKitRecord[ckTask.reminder] as! Bool
        self.reminderDate = (cloudKitRecord[ckTask.reminderDate] as! NSDate)
        self.title = cloudKitRecord[ckTask.title] as! String
        self.notes = cloudKitRecord[ckTask.notes] as! String
        self.localUpdate = (cloudKitRecord[ckTask.localUpdate] as! NSDate)
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: cloudKitRecord)
    }

    public func updateCKMetadata(from ckRecord: CKRecord) {
        self.setDefaultsForRemoteModify()
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: ckRecord)
    }
    
    public func managedObjectToNewCKRecord() -> CKRecord {
        guard ckMetadata == nil else {
            fatalError("CKMetaData exist, this should is not a new CKRecord")
        }
        
        let recordZoneID = CKRecordZoneID(zoneName: CloudKitZone.Todododo.rawValue, ownerName: CKCurrentUserDefaultName)
        let recordName = EntityName.Task + "." +  self.identifier
        let recordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        let ckRecord = CKRecord(recordType: RecordType.Task.rawValue, recordID: recordID)
        ckRecord[ckTask.title] = self.title as CKRecordValue
        ckRecord[ckTask.dueDate] = self.dueDate 
        ckRecord[ckTask.archived] = self.archived as CKRecordValue
        ckRecord[ckTask.localUpdate] = self.localUpdate
        ckRecord[ckTask.identifier] = self.identifier as CKRecordValue
        ckRecord[ckTask.reminderDate] = self.reminderDate
        ckRecord[ckTask.reminder] = self.reminder as CKRecordValue
        ckRecord[ckTask.completionDate] = self.completionDate
        ckRecord[ckTask.completed] = self.completed as CKRecordValue
        ckRecord[ckTask.notes] = self.notes as CKRecordValue
        if let locationAnnotation = self.location {
            ckRecord[ckTask.location] = CoreDataHelper.sharedInstance.ckReferenceOf(locationAnnotation: locationAnnotation)
        } else {
            ckRecord[ckTask.location] = nil
        }
        return ckRecord
    }
    
    public func managedObjectToUpdatedCKRecord() -> CKRecord {
        guard let ckMetadata = self.ckMetadata else {
            fatalError("CKMetadata is required to update CKRecord")
        }
        
        let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
        ckRecord[ckTask.title] = self.title as CKRecordValue
        ckRecord[ckTask.localUpdate] = self.localUpdate
        ckRecord[ckTask.identifier] = self.identifier as CKRecordValue
        ckRecord[ckTask.reminderDate] = self.reminderDate
        ckRecord[ckTask.dueDate] = self.dueDate
        ckRecord[ckTask.archived] = self.archived as CKRecordValue
        ckRecord[ckTask.reminder] = self.reminder as CKRecordValue
        ckRecord[ckTask.completionDate] = self.completionDate
        ckRecord[ckTask.completed] = self.completed as CKRecordValue
        ckRecord[ckTask.notes] = self.notes as CKRecordValue
        if let locationAnnotation = self.location {
            ckRecord[ckTask.location] = CoreDataHelper.sharedInstance.ckReferenceOf(locationAnnotation: locationAnnotation)
        } else {
            ckRecord[ckTask.location] = nil
        }
        return ckRecord
    }
    
    public func getCKRecordID() -> CKRecordID {
        guard let ckMetadata = self.ckMetadata else {
            fatalError("CKMetaData is required to update CKRecord")
        }
        let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
        return ckRecord.recordID
    }
}
