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
    
    private static var sharedInstance: CoreDataStack!
    
    private init(modelName: String) {
        self.modelName = modelName
        CoreDataStack.sharedInstance = self
    }
    
    // Note: model name can't be change, only the first time initialize the model, other times will be ignored. 
    static func shared(modelName: String) -> CoreDataStack {
        switch (sharedInstance, modelName) {
        case let (nil, modelName):
            sharedInstance = CoreDataStack(modelName: modelName)
            return sharedInstance
        default:
            return sharedInstance
        }
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


