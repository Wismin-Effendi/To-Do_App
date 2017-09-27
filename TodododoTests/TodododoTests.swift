//
//  TodododoTests.swift
//  TodododoTests
//
//  Created by Wismin Effendi on 9/10/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import XCTest
import os.log
import ToDoCoreDataCloudKit
import CoreData
import MapKit
@testable import Todododo


// MARK: - Nothing here.  Please see ToDoCoreDataCloudKitTests for Unit Test

class TodododoTests: XCTestCase {
    
    let mainContext = createMainContextInMemory()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

func createMainContextInMemory() -> NSManagedObjectContext {
    
    // Initialize NSManagedObjectModel
    let modelURL = Bundle.main.url(forResource: "ToDoApp", withExtension: "momd")
    guard let model = NSManagedObjectModel(contentsOf: modelURL!) else { fatalError("model not found") }
    
    // Configure NSPersistentStoreCoordinator with an NSPersistentStore
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    try! psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
    
    // Create and return NSManagedObjectContext
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc
    
    return context
}


