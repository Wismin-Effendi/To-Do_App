//
//  CoreDataStack.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import Seam3

class CoreDataStack {
    
    var smStore: SMStore?
    
    private let modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    lazy var storeContainer: NSPersistentContainer = {
        
        SMStore.registerStoreClass()
        
        let container = NSPersistentContainer(name: self.modelName)
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let applicationDocumentsDirectory = urls.last {
            let url = applicationDocumentsDirectory.appendingPathComponent("ToDoAppCoreData.sqlite")
            let storeDescription = NSPersistentStoreDescription(url: url)
            storeDescription.type = SMStore.type
            storeDescription.setOption("iCloud.ninja.pragprog.careerfoundry.To-Do-App" as NSString, forKey: SMStore.SMStoreContainerOption)
            
            container.persistentStoreDescriptions = [storeDescription]
        
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
            return container
        }
        fatalError("Unable to access documents directory")
    }()
    
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()
    
    func saveContext() {
        guard managedContext.hasChanges else { return }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
}


// MARK: CloudKit support via Seam3 library (cocoapods)
extension CoreDataStack {
    
    func validateCloudKitAndSync(_ completion:@escaping (() -> Void)) {
        
        self.smStore?.verifyCloudKitConnectionAndUser() { (status, user, error) in
            guard status == .available, error == nil else {
                NSLog("Unable to verify CloudKit Connection \(error!)")
                return
            }
            
            guard let currentUser = user else {
                NSLog("No current CloudKit user")
                return
            }
            
            let previousUser = UserDefaults.standard.string(forKey: "CloudKitUser")
            
            if previousUser != currentUser {
                do {
                    print("New user")
                    try self.smStore?.resetBackingStore()
                } catch {
                    NSLog("Error resetting backing store - \(error.localizedDescription)")
                    return
                }
            }
            
            UserDefaults.standard.set(currentUser, forKey: "CloudKitUser")
            
            self.smStore?.triggerSync(complete: true)
            
            completion()
        }
    }
}

