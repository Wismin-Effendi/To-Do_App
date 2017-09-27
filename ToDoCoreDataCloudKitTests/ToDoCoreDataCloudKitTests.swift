//
//  ToDoCoreDataCloudKitTests.swift
//  ToDoCoreDataCloudKitTests
//
//  Created by Wismin Effendi on 8/18/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import XCTest
import CoreData
import CoreLocation
import os.log
@testable import ToDoCoreDataCloudKit

class ToDoCoreDataCloudKitTests: XCTestCase {
    
    var mainContext: NSManagedObjectContext!
    var tasksWithoutLocations = ["First no loc", "Second no loc", "Third no loc"]
    var tasksWithAppleLocation = ["Buy iPhone 8", "Buy new iPad", "Buy MacBookPro", "But new iMac", "Buy iWatch", "Buy iMac Pro"]
    var tasksWithAustinLocation = ["Tours of City Hall", "The People's Gallery", "Meet the Major", "City Council meeting"]
    var appleLocationAnnotation: LocationAnnotation!
    var austinCityHallLocationAnnotation: LocationAnnotation!
    
    override func setUp() {
        super.setUp()
        mainContext = createMainContextInMemory()
        let appleLocation = AppleLocation()
        CoreDataTestUtil.createLocationAnnotation(location: appleLocation, moc: mainContext)
        let austinCityHallLocation = AustinCityHall()
        CoreDataTestUtil.createLocationAnnotation(location: austinCityHallLocation, moc: mainContext)
        appleLocationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: appleLocation.title, moc: mainContext)
        austinCityHallLocationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: austinCityHallLocation.title, moc: mainContext)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testLocationAnnotation() {
        let appleLocation = AppleLocation()
        let austinCityHallLocation = AustinCityHall()
        let appleLocationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: appleLocation.title, moc: mainContext)
        let austinCityHallLocationAnnotation = CoreDataUtil.getALocationAnnotationOf(locationIdentifier: austinCityHallLocation.title, moc: mainContext)
        XCTAssertNotNil(appleLocationAnnotation)
        XCTAssertNotNil(austinCityHallLocationAnnotation)
    }
    
    func testCreateTaskWithoutLocation() {
        for taskName in tasksWithoutLocations {
            let identifier = UUID().uuidString
            let title = taskName
            CoreDataTestUtil.createOneTask(identifier: identifier, title: title, location: nil, moc: mainContext)
            let task = CoreDataTestUtil.getTask(title: title, moc: mainContext)
            XCTAssertNotNil(task)
            XCTAssertEqual(title, task?.title)
            XCTAssertNil(task?.location)
        }
    }
    
    func testCreateTasksForAppleLocation() {
        for taskName in tasksWithAppleLocation {
            createTaskWithLocation(title: taskName, location: appleLocationAnnotation)
        }
    }
    
    func testCreateTasksForAustinCityHallLocation() {
        for taskName in tasksWithAppleLocation {
            createTaskWithLocation(title: taskName, location: austinCityHallLocationAnnotation)
        }
    }
    
    private func createTaskWithLocation(title: String, location: LocationAnnotation) {
        let identifier = UUID().uuidString
        CoreDataTestUtil.createOneTask(identifier: identifier, title: title, location: location, moc: mainContext)
        let task = CoreDataTestUtil.getTask(title: title, moc: mainContext)
        XCTAssertNotNil(task)
        XCTAssertEqual(title, task?.title)
        XCTAssertEqual(location, task?.location)
    }
    
    func testArchiveLocation() {
        let taskName = "Buy Apple TV"
        createTaskWithLocation(title: taskName, location: appleLocationAnnotation)
        let task = CoreDataTestUtil.getTask(title: taskName, moc: mainContext)!
        var archivedTaskCount = CoreDataTestUtil.getCountArchivedTask(moc: mainContext)
        XCTAssertEqual(0, archivedTaskCount)
        CoreDataTestUtil.updateTaskArchived(task: task)
        archivedTaskCount = CoreDataTestUtil.getCountArchivedTask(moc: mainContext)
        XCTAssertEqual(1, archivedTaskCount)
        let pendingDeleteTaskCount = CoreDataTestUtil.getCountPendingDeletionTask(moc: mainContext)
        XCTAssertEqual(0, pendingDeleteTaskCount)
    }
    
    func testTaskPendingDeletion() {
        let taskName = "Protest the Austin Major"
        createTaskWithLocation(title: taskName, location: austinCityHallLocationAnnotation)
        let task = CoreDataTestUtil.getTask(title: taskName, moc: mainContext)!
        var pendingDeleteTaskCount = CoreDataTestUtil.getCountPendingDeletionTask(moc: mainContext)
        XCTAssertEqual(0, pendingDeleteTaskCount)
        CoreDataTestUtil.updateTaskPendingDeletion(task: task)
        pendingDeleteTaskCount = CoreDataTestUtil.getCountPendingDeletionTask(moc: mainContext)
        XCTAssertEqual(1, pendingDeleteTaskCount)
        let archivedTaskCount = CoreDataTestUtil.getCountArchivedTask(moc: mainContext)
        XCTAssertEqual(0, archivedTaskCount)
        
    }
    
    private func createTaskWithLocationPendingDeletion(title: String, location: LocationAnnotation) {
        let identifier = UUID().uuidString
        CoreDataTestUtil.createOneTask(identifier: identifier, title: title, location: location, moc: mainContext)
        let task = CoreDataTestUtil.getTask(title: title, moc: mainContext)!
        CoreDataTestUtil.updateTaskPendingDeletion(task: task)
        XCTAssertEqual(title, task.title)
        XCTAssertEqual(location, task.location)
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

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct CoreDataTestUtil {
    
    static func createOneTask(identifier: String, title: String, location: LocationAnnotation?, moc: NSManagedObjectContext) {
        let task = Task(context: moc)
        task.setDefaultsForLocalCreate()
        task.identifier = identifier
        task.title = title
        if let location = location {
            task.location = location
        }
        do {
            try moc.save()
        } catch let error as NSError {
            os_log("Error try to create one sample task: %@", log: .default, type: .default, error.debugDescription)
        }
    }
    
    static func createLocationAnnotation(location: LocationAnnotationALike, moc: NSManagedObjectContext) {
        let title = location.title
        let subtitle = location.subtitle
        let coordinate2D: CLLocationCoordinate2D = location.coordinate2D
        let anno = TaskLocation(title: title, subtitle: subtitle, coordinate: coordinate2D)
        
        createLocationAnnotation(identifier: title, annotation: anno, moc: moc)
    }
    
    static func createLocationAnnotation(identifier: String, annotation: TaskLocation, moc: NSManagedObjectContext) {
        let location = LocationAnnotation(context: moc)
        location.setDefaultsForLocalCreate()
        location.identifier = identifier
        location.title = annotation.title!
        location.annotation = annotation
        do {
            try moc.save()
            print("We just create location annotation")
            os_log("We successfully save the Location Annotation", log: .default, type: .debug)
        } catch let error as NSError {
            fatalError("Failed to create sample LocationAnnotation item. \(error.localizedDescription)")
        }
    }
    
    static func getTask(title: String, moc: NSManagedObjectContext) -> Task? {
        let predicate = NSPredicate.init(format: "%K == %@", #keyPath(Task.title), title)
        return CoreDataUtil.getTasks(predicate: predicate, moc: moc).first
    }
    
    static func getCountArchivedTask(moc: NSManagedObjectContext) -> Int {
        let predicate = NSPredicate.init(format: "%K == YES", #keyPath(Task.archived))
        return CoreDataUtil.getTasks(predicate: predicate, moc: moc).count
    }
    
    static func getCountPendingDeletionTask(moc: NSManagedObjectContext) -> Int {
        let predicate = NSPredicate.init(format: "%K == YES", #keyPath(Task.pendingDeletion))
        return CoreDataUtil.getTasks(predicate: predicate, moc: moc).count
    }
    
    static func getCountTask(moc: NSManagedObjectContext) -> Int {
        let predicate = NSPredicate.init(format: "TRUEPREDICATE")
        return CoreDataUtil.getTasks(predicate: predicate, moc: moc).count
    }
    
    static func updateTaskArchived(task: Task) {
        task.archived = true
        do {
            try task.managedObjectContext?.save()
            os_log("We successfully save update task as archived")
        } catch let error as NSError {
            fatalError("Failed to save updated archived task. \(error.localizedDescription)")
        }
    }
    
    static func updateTaskPendingDeletion(task: Task) {
        task.pendingDeletion = true
        do {
            try task.managedObjectContext?.save()
            os_log("We successfully save update task as pending deletion")
        } catch let error as NSError {
            fatalError("Failed to save updated pending deletion task. \(error.localizedDescription)")
        }
    }
}

protocol LocationAnnotationALike {
    var title: String { get }
    var subtitle: String { get}
    var coordinate2D: CLLocationCoordinate2D { get }
}

struct AppleLocation: LocationAnnotationALike {
    let title = "Apple Campus"
    let subtitle = "1 Infinite Loop, Cupertino, CA 95014"
    let coordinate2D = CLLocationCoordinate2D(latitude: 37.332051, longitude: -122.031180)
}

struct AustinCityHall: LocationAnnotationALike {
    let title = "Austin City Hall"
    let subtitle = "301 W 2nd St, Austin, TX 78701"
    let coordinate2D = CLLocationCoordinate2DMake(30.265133, -97.746956)
}
