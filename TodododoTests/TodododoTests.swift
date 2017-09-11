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

class TodododoTests: XCTestCase {
    
    let coreDataStack = CoreDataStack.shared(modelName: ModelName.ToDo)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testCreateTaskWithoutLocation() {
        let identifier = UUID().uuidString
        let title = "Important task without location"
        let moc = coreDataStack.managedContext
        CoreDataTestUtil.createOneTask(identifier: identifier, title: title, moc: moc)
        let task = CoreDataUtil.getTask(identifier: identifier, moc: moc)
        XCTAssertNotNil(task)
        XCTAssertNil(task?.location)
        XCTAssertEqual(title, task?.title)
    }
    
    func testCreateOneLocation() {
        let identifier = UUID().uuidString
        let moc = coreDataStack.managedContext
        CoreDataTestUtil.createAppleLocation(identifier: identifier, moc: moc)
        sleep(5)
        let locationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: identifier, moc: moc)!
        let annotation = locationAnnotation.annotation as! TaskLocation
        XCTAssertEqual(annotation.title, AppleLocation.title)
        XCTAssertEqual(annotation.coordinate.latitude, AppleLocation.coordinate2D.latitude)
        XCTAssertEqual(annotation.coordinate.longitude, AppleLocation.coordinate2D.longitude)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

struct CoreDataTestUtil {
    
    static func createOneTask(identifier: String, title: String, moc: NSManagedObjectContext) {
        let task = Task(context: moc)
        task.setDefaultsForLocalCreate()
        task.identifier = identifier
        task.title = title
        do {
            try moc.save()
        } catch let error as NSError {
            os_log("Error try to create one sample task: %@", log: .default, type: .default, error.debugDescription)
        }
    }
    
    static func createAppleLocation(identifier: String, moc: NSManagedObjectContext) {
        let title = AppleLocation.title
        let subtitle = AppleLocation.subtitle
        let coordinate2D: CLLocationCoordinate2D = AppleLocation.coordinate2D
        let anno = TaskLocation(title: title, subtitle: subtitle, coordinate: coordinate2D)
        
        CoreDataUtil.createLocationAnnotation(identifier: identifier, annotation: anno, moc: moc)
    }
    
}

struct AppleLocation {
    static let title = "Apple Campus"
    static let subtitle = "1 Infinite Loop, Cupertino, CA 95014"
    static let coordinate2D = CLLocationCoordinate2D(latitude: 37.332051, longitude: -122.031180)
}
