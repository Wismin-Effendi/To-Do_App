//
//  To_Do_AppTests.swift
//  To-Do AppTests
//
//  Created by Wismin Effendi on 6/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import XCTest
import os.log
import ToDoCoreDataCloudKit
import CoreData
import CoreLocation
@testable import Todododo

class To_Do_AppTests: XCTestCase {
    
    let coreDataStack = CoreDataStack.shared(modelName: ModelName.ToDo)
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
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
        let locationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: identifier, moc: moc)!
        let annotation = locationAnnotation.annotation as! TaskLocation
        XCTAssertEqual(annotation.title, AppleLocation.title)
        XCTAssertEqual(annotation.coordinate.latitude, AppleLocation.coordinate2D.latitude)
        XCTAssertEqual(annotation.coordinate.longitude, AppleLocation.coordinate2D.longitude)
    }
    
    func testCreateTaskWithLocation() {
        
    }
    
    func modifyLocationOfTheTask() {
        
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
        let coordinate = AppleLocation.coordinate2D
        let annotation = TaskLocation(title: title, subtitle: subtitle, coordinate: coordinate)
        CoreDataUtil.createLocationAnnotation(identifier: identifier, annotation: annotation, moc: moc)
    }
    
}


struct AppleLocation {
    static let title = "Apple Campus"
    static let subtitle = "1 Infinite Loop, Cupertino, CA 95014"
    static let coordinate2D = CLLocationCoordinate2D(latitude: 37.332051, longitude: -122.031180)
}

