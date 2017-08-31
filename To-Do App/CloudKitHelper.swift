//
//  CloudKitHelper.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/4/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import os.log


enum CloudKitUserDefaults: String {
    case createdCustomzone
    case subscribedToPrivateChanges
    case subscribedToSharedChanges
}

enum CustomCKError: Error {
    case fetchZoneError(Error)
    case createZoneError(Error)
}

enum ServerChangeToken: String {
    case DatabaseChangeToken
    case ZoneChangeToken
}


public class CloudKitHelper {
// Initializing Container 
    
    let coreDataHelper = CoreDataHelper.sharedInstance
    let container = CKContainer.default()
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let sharedDB: CKDatabase = CKContainer.default().sharedCloudDatabase
    let privateSubscriptionID = "private-changes"
    let sharedSubscriptionID = "shared-changes"
    
    let zoneKeyPrefix = "token4Zone-"
    let zoneID: CKRecordZoneID = CloudKitZone.Todododo.recordZoneID()
    
    var iCloudAvailable = false
    var setupCloudKitHasRun = false
    
    var fetchAllZonesOperations: CKFetchRecordZonesOperation!
    var modifyRecordZonesOperation: CKModifyRecordZonesOperation!
    var createPrivateDBSubscriptionOperation: CKModifySubscriptionsOperation!
    var createSharedDBSubscriptionOperation: CKModifySubscriptionsOperation!
    var saveToCloudKitOperation: CKModifyRecordsOperation!
    var fetchDatabaseChangesOperation: CKFetchDatabaseChangesOperation!
    var fetchRecordZoneChangesOperation: CKFetchRecordZoneChangesOperation!
    
    var databaseChangeToken: CKServerChangeToken? = nil
    var isRetryOperation = false
    
    // default to `false`
    var createdCustomZone = false
    var subscribedToPrivateChanges = false
    var subscribedToSharedChanges = false
    var needToFetchBeforeSave = false
    
    // we need to keep the reference for NSOperations around, so we use properties as their references
    var fetchRecordZoneOperation: CKFetchRecordZonesOperation?
    
    // Singleton
    public static var sharedInstance = CloudKitHelper()

    let managedObjectContext: NSManagedObjectContext
    
    private init() {
        managedObjectContext = CoreDataStack.shared(modelName: ModelName.ToDo).managedContext
    }
    
    
    public func setupCloudKit() {
        dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
        // Check iCloud account status
        checkCKAccountStatus(completion: nil)
        
        if iCloudAvailable {
            // Zones compliance
            setCustomZonesCompliance()
            // Sync first time 
            syncToCloudKit {
                os_log("First time sync after app start up")
            }
            // Create subscriptions
            createDBSubscription()
        }
        setupCloudKitHasRun = true
    }
    
    //MARK: - Check iCloud account status
    // It's okay to block and wait for result since we should be running this is GlobalQueue.
    public func checkCKAccountStatus(completion: ((CKAccountStatus) -> ())? )  {
        let group = DispatchGroup()
        group.enter()
        container.accountStatus {[unowned self] (accountStatus, error) in
            if error != nil  {
                os_log("Error checking CKAccountStatus: %@", error.debugDescription)
            }
            
            switch accountStatus {
            case .available: self.iCloudAvailable = true
            default: self.iCloudAvailable = false
            }
            completion?(accountStatus)
            group.leave()
        }
        
        let result = group.wait(timeout: DispatchTime.now() + 3)
        switch result {
        case .timedOut: self.iCloudAvailable = false
        case .success: break
        }
    }
    
    //MARK: - Modify custom zone to match CloudKitZones enums
    //
    
    // main function
    public func setCustomZonesCompliance() {
        // The following should run in strict order, use DispatchGroup and Wait to sync the process
        // 1. run fetch allZone (see helper func above)
        // 2. create zonesToCreate and zonesToDelete
        
        var recordZonesToSave: [CKRecordZone]?
        var recordZoneIDsToDelete: [CKRecordZoneID]?
        
        func processServerRecordZone(existingZoneIDs: [CKRecordZoneID]) -> ([CKRecordZone]?, [CKRecordZoneID]?) {
            
            func setZonesToCreate() -> [CKRecordZone]? {
                var recordZonesToCreate: [CKRecordZone]? = nil
                let existingZoneNames = existingZoneIDs.map {  $0.zoneName }
                let expectedZoneNamesSet = Set(CloudKitZone.allCloudKitZoneNames)
                let missingZoneNamesSet = expectedZoneNamesSet.subtracting(existingZoneNames)
                
                if missingZoneNamesSet.count > 0 {
                    recordZonesToCreate = missingZoneNamesSet.flatMap( { CloudKitZone(rawValue: $0) } )
                        .map { CKRecordZone(zoneID: $0.recordZoneID()) }
                }
                return recordZonesToCreate
            }
            
            func setZoneIDstoDelete() -> [CKRecordZoneID]? {
                var recordZoneIDsToDelete: [CKRecordZoneID]? = nil
                let customZoneIDsOnly = existingZoneIDs.filter { $0.zoneName != CKRecordZoneDefaultName }
                recordZoneIDsToDelete = customZoneIDsOnly.filter { CloudKitZone(rawValue: $0.zoneName) == nil }
                // we should return either nil or array with at least 1 member never empty array
                recordZoneIDsToDelete = recordZoneIDsToDelete!.isEmpty ? nil : recordZoneIDsToDelete
                return recordZoneIDsToDelete
            }
            
            return (setZonesToCreate(), setZoneIDstoDelete())
        }
        
        func fetchAndProcessRecordZones() {
            let group = DispatchGroup()
            
            var existingZoneIDs = [CKRecordZoneID]()
            group.enter()
            fetchAllZonesOperations = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
            fetchAllZonesOperations.fetchRecordZonesCompletionBlock = {[unowned self] recordZoneDict, error in
                
                guard error == nil else {
                    os_log("Error occured during fetch record zones operation: %@", error.debugDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: self.setCustomZonesCompliance)
                    return
                }
                
                existingZoneIDs = Array(recordZoneDict!.keys)
                os_log("Existing zones: %@", existingZoneIDs.map { $0.zoneName } )
                (recordZonesToSave, recordZoneIDsToDelete) = processServerRecordZone(existingZoneIDs: existingZoneIDs)
                group.leave()
            }
            privateDB.add(fetchAllZonesOperations)
            
            let result = group.wait(timeout: DispatchTime.now() + 3)
            switch result {
            case .timedOut:
                os_log("Timed out during fetch all zones operation")
            default: break
            }
        }

        
        // 3. run modifyRecordZone operation to create and delete zone for compliance
        func modifyRecordZones(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZoneID]?) {
            let group = DispatchGroup()
            group.enter()
            modifyRecordZonesOperation = CKModifyRecordZonesOperation(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
            modifyRecordZonesOperation.addDependency(fetchAllZonesOperations)
            if isRetryOperation { isRetryOperation = false } // need to reset the flag eventhough we don't use it here
            modifyRecordZonesOperation.modifyRecordZonesCompletionBlock = {[unowned self] modifiedRecordZones, deletedRecordZoneIDs, error in
                
                os_log("--CKModifyRecordZonesOperation.modifyRecordZonesOperation")

                guard error == nil else {
                    os_log("Error occured during modify record zones operation: %@", error.debugDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: self.setCustomZonesCompliance)
                    return
                }
                
                
                if let modifiedRecordZones = modifiedRecordZones {
                    modifiedRecordZones.forEach { os_log("Added recordZone: %@", $0) }
                }
                
                if let deletedRecordZoneIDs = deletedRecordZoneIDs {
                    deletedRecordZoneIDs.forEach { os_log("Deleted zoneID: %@", $0) }
                }
                
                self.createdCustomZone = true
                self.isRetryOperation = false
                group.leave()
            }
            privateDB.add(modifyRecordZonesOperation)
            let result = group.wait(timeout: DispatchTime.now() + 3)
            switch result {
            case .timedOut:
                os_log("Timed out during modify record zone operation")
            default: break
            }
        }
        
        fetchAndProcessRecordZones()
        modifyRecordZones(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
        
    }
    
    
    // MARK: - Subcribing to Change Notification
    // create subscription if not exists
    public func createDBSubscription() {
        subscribedToPrivateChanges = false
        subscribedToSharedChanges = false

        func WrapperCreateDBSubscription() {
            print("create private")
            let createPrivateDBSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: privateSubscriptionID)
            if !isRetryOperation {
                self.createPrivateDBSubscriptionOperation = createPrivateDBSubscriptionOperation
                createPrivateDBSubscriptionOperation.addDependency(modifyRecordZonesOperation)
            }
            createPrivateDBSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
                guard error == nil else {
                    os_log("Error occured during modify record zones operation: %@", error.debugDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: WrapperCreateDBSubscription)
                    return
                }
                
                self.subscribedToPrivateChanges = true
                
            }
            privateDB.add(createPrivateDBSubscriptionOperation)
            
            print("create shared")
            let createSharedDBSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: sharedSubscriptionID)
            if !isRetryOperation {
              self.createSharedDBSubscriptionOperation = createSharedDBSubscriptionOperation
            } else {
                isRetryOperation = false
            }
            createSharedDBSubscriptionOperation.addDependency(createPrivateDBSubscriptionOperation)
            createSharedDBSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
                guard error == nil else {
                    os_log("Error occured during modify record zones operation: %@", error.debugDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: self.createDBSubscription)
                    return
                }
                self.subscribedToSharedChanges = true
            }
            sharedDB.add(createSharedDBSubscriptionOperation)
        }
        WrapperCreateDBSubscription()
    }
    
    
    // MARK: - Fetch from CloudKit and Save to CloudKit
    public func syncToCloudKit(fetchCompletion: @escaping () -> Void) {
        guard iCloudAvailable else { return }
        dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
        needToFetchBeforeSave = true
        fetchOfflineServerChanges(completion: fetchCompletion)
        saveLocalChangesToCloudKit()
    }
    
    public func savingToCloudKitOnly() {
        guard iCloudAvailable else {
            setupCloudKit()
            return
        }
        dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
        needToFetchBeforeSave = false
        saveLocalChangesToCloudKit()
    }
    
    private func fetchOfflineServerChanges(completion: @escaping () -> Void) {
        print(self.createdCustomZone)
        fetchChanges(in: .private, completion: completion)
    }
    
    public func createDatabaseSubscriptionOperation(subscriptionID: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionID)
        
        let notificationInfo = CKNotificationInfo()
        
        // send a silent notification 
        
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        
        return operation
    }
    
    
    
    public func fetchChanges(in databaseScope: CKDatabaseScope, completion: @escaping () -> Void) {
    
        switch databaseScope {
        case .private:
            fetchDatabaseChanges(database: self.privateDB, databaseTokenKey: "private", completion: completion)
        case .shared:
            fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "shared", completion: completion)
        case .public:
            fatalError()
        }
        
    }
    
    public func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping () -> Void) {
        
        dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
        print("we are in fetch DB change for")
        guard iCloudAvailable else {
            os_log("Attempt to fetch DB changes but iCloud not available")
            return
        }
        
        var changedZoneIDs = [CKRecordZoneID]()
        
        let changeToken: CKServerChangeToken? = {
            guard let data = UserDefaults.standard.data(forKey: ServerChangeToken.DatabaseChangeToken.rawValue) else { return nil }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
        }()
        
        if let changeToken = changeToken {
            print("We have the following change token: \(changeToken)")
        } else {
            print("Change token is nil")
        }
        
        func WrapperFetchDatabaseChangesOperation() {
            
            let fetchDatabaseChangesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
            
            if !subscribedToPrivateChanges && !isRetryOperation {
                fetchDatabaseChangesOperation.addDependency(modifyRecordZonesOperation)
            }
            
            if !isRetryOperation {
                self.fetchDatabaseChangesOperation = fetchDatabaseChangesOperation
            } else {
                isRetryOperation = false
            }
            
            fetchDatabaseChangesOperation.recordZoneWithIDChangedBlock = { (zoneID) in
                changedZoneIDs.append(zoneID)
            }
            
            fetchDatabaseChangesOperation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
                // write this zone deletion to memory
            }
            
            fetchDatabaseChangesOperation.changeTokenUpdatedBlock = {[unowned self] (token) in
                // Flush zone deletion for this database to disk
                // Write this new database change token to memory
                
                self.databaseChangeToken = token
                
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                UserDefaults.standard.set(data, forKey: ServerChangeToken.DatabaseChangeToken.rawValue)
                UserDefaults.standard.synchronize()
            }
            
            
            fetchDatabaseChangesOperation.fetchDatabaseChangesCompletionBlock = {[unowned self] (token, moreComing, error) in
                guard error == nil else {
                    os_log("Error occured during fetch database changes operations: %@", error!.localizedDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: WrapperFetchDatabaseChangesOperation)
                    completion()
                    return
                }
                
                print("We are in fetch db changes completion block..")
                
                // Flush zone deletions for this database to disk
                // Write this new database change token to memory
                if let token = token {
                    let data = NSKeyedArchiver.archivedData(withRootObject: token)
                    UserDefaults.standard.set(data, forKey: ServerChangeToken.DatabaseChangeToken.rawValue)
                    UserDefaults.standard.synchronize()
                }
                
                self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
                    // Flush in memory database change token to disk
                    
                    os_log("We are done with fetch zone changes....")
                    completion()
                }
            }
            print("are we here...?")
            database.add(fetchDatabaseChangesOperation)
        }
        WrapperFetchDatabaseChangesOperation()
    }
    
    
    public func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZoneID],
                          completion: @escaping () -> Void) {
        
        // Look up the previous change token for each zone 
        
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        
        for zoneID in zoneIDs {
            
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = {
                let zoneKey =  zoneKeyPrefix + "\(zoneID.zoneName)"
                guard let data = UserDefaults.standard.data(forKey: zoneKey) else { return nil }
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
            }()
            // just at test 
            // options.previousServerChangeToken = nil
            optionsByRecordZoneID[zoneID] = options
        }
        
        func WrapperFetchRecordZoneChangesOperation() {
            
            let fetchRecordZoneChangesOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
            
            if !isRetryOperation {
                self.fetchRecordZoneChangesOperation = fetchRecordZoneChangesOperation
            } else {
                isRetryOperation = false
            }
            
            fetchRecordZoneChangesOperation.recordChangedBlock = {[unowned self] (ckRecord: CKRecord) in
                print("Record changed:", ckRecord)
                // Write this record change to memory
                self.coreDataHelper.insertOrUpdateManagedObject(using: ckRecord, managedObjectContext: self.managedObjectContext)
            }
            
            fetchRecordZoneChangesOperation.recordWithIDWasDeletedBlock = {[unowned self] (recordID, someString) in
                print("What is this? ", someString)
                print("Record deleted:", recordID)
                // write this record deletion to memory
                self.coreDataHelper.deleteManagedObject(using: recordID, managedObjectContext: self.managedObjectContext)
            }
            
            fetchRecordZoneChangesOperation.recordZoneChangeTokensUpdatedBlock = { (zoneID, token, data) in
                // Flush record changes and deletions for this zone to disk
                DispatchQueue.main.async {
                    try! self.managedObjectContext.save()
                }
                
                // Write this new zone change token to disk
                guard let changeToken: CKServerChangeToken = token else { return }
                let zoneKey =  self.zoneKeyPrefix + "\(zoneID.zoneName)"
                let data = NSKeyedArchiver.archivedData(withRootObject: changeToken)
                UserDefaults.standard.set(data, forKey: zoneKey)
                UserDefaults.standard.synchronize()
                
            }
            
            fetchRecordZoneChangesOperation.recordZoneFetchCompletionBlock = {[unowned self] (zoneID, changeToken, _, _, error) in
                
                if let error = error as? CKError {
                    let errorCode = error.errorCode
                    let cloudKitError = CloudKitError(rawValue: errorCode)!
                    switch cloudKitError {
                    case .CKErrorChangeTokenExpired:
                        for zoneID in zoneIDs {
                            let options = CKFetchRecordZoneChangesOptions()
                            options.previousServerChangeToken = nil
                            optionsByRecordZoneID[zoneID] = options
                        }
                        WrapperFetchRecordZoneChangesOperation()
                    default: break
                    }
                    
                    os_log("Error on fetch record zone change with ErrorCode: %@", cloudKitError.description)
                    print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                    completion()
                    return
                }
                // Handle changeToken
                
                
                DispatchQueue.main.async {
                    try! self.managedObjectContext.save()
                }
                
                
                
                // Write this new zone change token to disk
                guard let changeToken: CKServerChangeToken = changeToken else { return }
                let zoneKey =  self.zoneKeyPrefix + "\(zoneID.zoneName)"
                let data = NSKeyedArchiver.archivedData(withRootObject: changeToken)
                UserDefaults.standard.set(data, forKey: zoneKey)
                UserDefaults.standard.synchronize()
                
            }
            
            fetchRecordZoneChangesOperation.fetchRecordZoneChangesCompletionBlock = { (error) in
                guard error == nil else {
                    os_log("Error fetching zone changes for %@ database: %@", databaseTokenKey, error!.localizedDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: WrapperFetchRecordZoneChangesOperation)
                    return
                }
                print("We are good...")
                completion()
            }
            database.add(fetchRecordZoneChangesOperation)
        }
        WrapperFetchRecordZoneChangesOperation()
    }

    // MARK: - General helper
    
    public static func encodeMetadata(of cloudKitRecord: CKRecord) -> NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: data)
        coder.requiresSecureCoding = true
        cloudKitRecord.encodeSystemFields(with: coder)
        coder.finishEncoding()
        
        return data
    }
    
    public static func decodeMetadata(from data: NSData) -> CKRecord {
        // setup the CKRecord with its metadata only
        let coder = NSKeyedUnarchiver(forReadingWith: data as Data)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)!
        coder.finishDecoding()
        
        // now we have bare CKRecord with only Metadata
        // we need to add the custom fields to be useful 
        return record
    }
    
    private func retryCKOperation(of error: CKError, f: @escaping () -> Void) {
        if let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? Double {
            let delayTime = DispatchTime.now() + retryAfter
            DispatchQueue.global().asyncAfter(deadline: delayTime, execute: f)
        }
    }
    
    private func handlingCKOperationError(of error: Error, retryableFunction: @escaping () -> Void) {
        isRetryOperation = true
        if let error = error as? CKError {
            let errorCode = error.errorCode
            let cloudKitError = CloudKitError(rawValue: errorCode)!
            if cloudKitError.isFatalError() {
                os_log("We got fatal error: %@", cloudKitError.description)
            } else if cloudKitError.isRetryCase() {
                os_log("We got retryable ")
                isRetryOperation = true
                retryCKOperation(of: error, f: retryableFunction)
            } else {
                os_log("We got neither fatal nor retryable CKError: %@", cloudKitError.description)
            }
        }
    }
    
    //MARK: - To save localChanges in CoreData to CloudKit


    private func saveLocalChangesToCloudKit() {
        let group = DispatchGroup()
        
        let recordsToSave = coreDataHelper.getRecordsToModify(managedObjectContext: managedObjectContext)
        let recordIDsToDelete = coreDataHelper.getRecordIDsForDeletion(managedObjectContext: managedObjectContext)
        
        func WrapperSaveToCloudKitOperation() {
            let saveToCloudKitOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
            if !isRetryOperation {
                self.saveToCloudKitOperation = saveToCloudKitOperation
                if needToFetchBeforeSave {
                    saveToCloudKitOperation.addDependency(fetchDatabaseChangesOperation)
                }
            } else {
                isRetryOperation = false
            }
            
            saveToCloudKitOperation.isAtomic = true
            saveToCloudKitOperation.savePolicy = .changedKeys
            saveToCloudKitOperation.modifyRecordsCompletionBlock = {[unowned self] (modifiedCKRecords, deletedRecordIDs, error) in
                guard error == nil else {
                    os_log("Error occured during save local change to CloudKit: %@", error!.localizedDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: WrapperSaveToCloudKitOperation)
                    return
                }
                self.coreDataHelper.postSuccessfyModifyOnCloudKit(modifiedCKRecords: modifiedCKRecords!, managedObjectContext: self.managedObjectContext)
                self.coreDataHelper.postSuccessfulDeletionOnCloudKit(managedObjectContext: self.managedObjectContext)
                group.leave()
            }
            privateDB.add(saveToCloudKitOperation)
        }
        group.enter()
        WrapperSaveToCloudKitOperation()
        let result = group.wait(timeout: DispatchTime.now() + 2)
        switch result {
        case .timedOut:
            os_log("Timed out save local change to iCloud")
        default:
            break
        }
    }
}














