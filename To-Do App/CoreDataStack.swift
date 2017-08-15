//
//  CoreDataStack.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    private let modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    lazy var storeContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: self.modelName)
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let applicationDocumentsDirectory = urls.last {
            let url = applicationDocumentsDirectory.appendingPathComponent("ToDoAppCoreData.sqlite")
            let storeDescription = NSPersistentStoreDescription(url: url)
            
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


