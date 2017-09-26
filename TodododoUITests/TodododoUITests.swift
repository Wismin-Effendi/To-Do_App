//
//  TodododoUITests.swift
//  TodododoUITests
//
//  Created by Wismin Effendi on 9/10/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import XCTest
import os.log


struct TabBarTitle {
    static let Location = "Location"
    static let Time = "Time"
    static let Archived = "Archived"
}

struct Alert {
    struct Title {
        static let iTunesSignIn = "Sign In to iTunes Store"
        static let chooseLocation = "Choose Location"
        static let tenLocationsFound = "10 locations found"
        static let pleaseUpgrade = "Please Upgrade"
    }
    struct Button {
        static let OK = "OK" 
        static let Later = "Later"
        static let Upgrade = "Upgrade"
        static let Dismiss = "Dismiss"
        static let Cancel = "Cancel"

    }
}

struct NavBar {
    struct Button {
        static let Cancel = "Cancel"
        static let Save = "Save"
        static let Add = "Add"
        static let Done = "Done"
    }

    struct Title {
        static let byDueDate = "Task by due date"
        static let byLocation = "Task by location"
        static let archivedTask = "Archived Task"
        static let chooseLocation = "Choose Location"
        static let upgrade = "Upgrade"
        static let licenses = "Licenses"
        static let settings = "Settings"
    }
}

struct MapVC {
    struct TextField {
        static let searchText = "Enter Business or Landmark or Address"
    }
    struct AnnotationText {
        static let Ranch99_Grant_Rd = "99 Ranch Market, 1350 Grant Rd, Mountain View, CA  94040, United States"
        static let Chicken99 = "99 Chicken, 2781 El Camino Real, Santa Clara, CA  95051, United States"
        static let LowT99  = "Low T 99, 5150 Graves Ave, Unit 11H, San Jose, CA  95129, United States"
    }
}

struct DetailView {
    static let tableButtonEdit = "Edit"
}

struct LocationTitle {
    static let Ranch99 = "99 Ranch Market"
}

struct TableCellButton {
    static let archive = "archive custom"
    static let reschedule = "clock custom"
    static let completed = "checked"
    static let delete = "Delete"
}

// Note: This UI test are designed to run on iPhone only. 
// Modification might be needed for iPad, it's beyond the scope at this time. 
// Instead we manually tested the iPad version for regression after this UI test. 

class TodododoUITests: XCTestCase {
    
    let app = XCUIApplication()
    let doesExists = NSPredicate(format: "exists == true")

    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSelectAllCellsInFirstTab() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let iTunesSignInAlert = app.alerts["Sign In to iTunes Store"]
        if iTunesSignInAlert.exists {
            iTunesSignInAlert.buttons["Cancel"].tap()
        }
        
        let tabBarsQuery = app.tabBars
        let locationButton = tabBarsQuery.buttons["Location"]
        let archivedButton = tabBarsQuery.buttons["Archived"]
        let timeBasedButton = tabBarsQuery.buttons["Time"]
        locationButton.tap()
        archivedButton.tap()
        timeBasedButton.tap()
        // locationButton.tap()
        
        let tablesQuery = app.tables
        let cellsCount = tablesQuery.element(boundBy: 0).cells.count
        print("Number of cells: \(cellsCount)")
        
        for idx in 0..<cellsCount {
            let cell = tablesQuery.cells.element(boundBy: idx)
            cell.tap()
            let cancelButton = app.navigationBars.buttons["Cancel"]
            cancelButton.tap()
        }
    }
    
    func addSeveralTasksWithoutLocation(count: Int) {
        handle_iTunesLogin()

        for _ in 1...count {
            app.navigationBars["Task by due date"].buttons["Add"].tap()
            app.navigationBars.buttons["Save"].tap()
        }
    }
    
    func handle_iTunesLogin() {
        let signInAlert = app.alerts["Sign In to iTunes Store"]
        if signInAlert.exists {
            signInAlert.buttons["Cancel"].tap()
        }
    }
    
    func pickAnyOneLocation() {
        // should be in Task detail view already 
        XCTAssertTrue(app.navigationBars.buttons["Save"].exists)
        XCTAssertTrue(app.navigationBars.buttons["Cancel"].exists)
        let tablesQuery = app.tables
        tablesQuery.buttons["Edit"].tap()
        // select in Location List
        XCTAssertTrue(app.navigationBars["Choose Location"].exists)
        let ranch99 = tablesQuery.element(boundBy: 0).cells.textFields["99 Ranch Market"]
        ranch99.tap()
        // check in TaskEdit page
        XCTAssertTrue(tablesQuery.element(boundBy: 0).cells.textFields["99 Ranch Market"].exists)
        app.navigationBars.buttons["Save"].tap()
    }

     func getTotalTasksCount() -> Int {
        let tablesQuery = app.tables
        app.tabBars.buttons["Time"].tap()
        let activeTasksCount = tablesQuery.element(boundBy: 0).cells.count
        print(activeTasksCount)
        app.tabBars.buttons["Archived"].tap()
        let archivedTasksCount = tablesQuery.element(boundBy: 0).cells.count
        print(archivedTasksCount)
        return Int(activeTasksCount + archivedTasksCount)
    }
    
    
    func trimTasksToMaxTotal(count: Int) {
        let totalCount = getTotalTasksCount()
        let maxEachType = totalCount / 2
        
        let tabBarsQuery = app.tabBars
        let tablesQuery = app.tables
        let locationButton = tabBarsQuery.buttons["Location"]
        let archivedButton = tabBarsQuery.buttons["Archived"]
        
        locationButton.tap()
        let activeTaskCount = Int(tablesQuery.element(boundBy: 0).cells.count)
        let numActiveTasksToDelete = activeTaskCount - maxEachType
        if numActiveTasksToDelete > 0 {
            deleteActiveTasks(count: numActiveTasksToDelete)
        }
        
        archivedButton.tap()
        let archivedTaskCount = Int(tablesQuery.element(boundBy: 0).cells.count)
        let numArchivedTaskToDelete = archivedTaskCount - maxEachType
        if numArchivedTaskToDelete > 0 {
            deleteArchivedTasks(count: numArchivedTaskToDelete)
        }
    }

    func testTrimTasks() {
        trimTasksToMaxTotal(count: 18)
    }
    
    func testEditTaskLocation() {
        
        let tabBarsQuery = app.tabBars
        let locationButton = tabBarsQuery.buttons["Location"]
        locationButton.tap()
        let tablesQuery = app.tables
        let cellsCount = tablesQuery.element(boundBy: 0).cells.count
        // edit the last cell 
        let lastCellIndex = cellsCount - UInt(1)
        let lastCell = tablesQuery.cells.element(boundBy: lastCellIndex)
        lastCell.tap()
        let editButton = tablesQuery.buttons["Edit"]
        editButton.tap()
        XCTAssertTrue(app.navigationBars["Choose Location"].exists) 
        let locationCell = tablesQuery.element(boundBy: 0).cells.staticTexts["99 Ranch Market"]
        locationCell.tap()
        let locationTitle = "99 Ranch Market"
        XCTAssertTrue(tablesQuery.element(boundBy: 0).cells.staticTexts[locationTitle].exists)
    }
    
    
    
    func deleteArchivedTasks(count: Int) {
        
        app.tabBars.buttons["Archived"].tap()
        let tablesQuery = app.tables
        let cellsCount = tablesQuery.element(boundBy: 0).cells.count
        guard cellsCount > 0 else {
            XCTFail("Table has not cell")
            return
        }
        
        let countCellsToDelete = min(Int(cellsCount), count)
        for _ in 0..<countCellsToDelete {
            let cell = tablesQuery.cells.element(boundBy: 0)
            cell.swipeLeft()
            cell.buttons["Delete"].tap()
        }
    }
    
    func testDeleteAllArchivedTasks() {
        app.tabBars.buttons["Archived"].tap()
        let tablesQuery = app.tables
        let beforeCellsCount = tablesQuery.element(boundBy: 0).cells.count
        rescheduleFromArchive(count: Int(beforeCellsCount))
        
        deleteArchivedTasks(count: Int(beforeCellsCount))
        
        let cellsCount = tablesQuery.element(boundBy: 0).cells.count
        XCTAssertTrue(cellsCount == 0)
        
        archiveTasks(count: Int(beforeCellsCount))
    }
    
    func archiveTasks(count: Int) {
        guard count > 0 else {
            fatalError("got count: \(count)")
        }
        let tabBarsQuery = app.tabBars
        let tablesQuery = app.tables
        let archivedTab = tabBarsQuery.buttons["Archived"]
        archivedTab.tap()
        let archivedCellCountBefore = tablesQuery.element(boundBy: 0).cells.count
        
        let timeTab = tabBarsQuery.buttons["Time"]
        timeTab.tap()
        let timeCellCountBefore = tablesQuery.element(boundBy: 0).cells.count
        
        let currentCount = Int(tablesQuery.element(boundBy: 0).cells.count)
        let countCellsToArchive = min(currentCount, count)
        
        // archive tasks
        for _ in 1...countCellsToArchive {
            let cell = tablesQuery.cells.element(boundBy: 0)
            expectation(for: doesExists, evaluatedWith: cell, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
            cell.swipeRight()
            let archiveButton = tablesQuery.buttons[TableCellButton.archive]
            expectation(for: doesExists, evaluatedWith: archiveButton, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
            archiveButton.tap()
            print("blah")
        }
        XCTAssertEqual(tablesQuery.element(boundBy: 0).cells.count, timeCellCountBefore - UInt(countCellsToArchive))
        
        archivedTab.tap()
        XCTAssertEqual(tablesQuery.element(boundBy: 0).cells.count, archivedCellCountBefore + UInt(countCellsToArchive))
        
    }
    
    func deleteActiveTasks(count: Int) {
        guard count > 0 else { return }
        app.tabBars.buttons["Location"].tap()
        let tablesQuery = app.tables
        
        let currentCount = Int(tablesQuery.element(boundBy: 0).cells.count)
        let countCellsToDelete = min(currentCount, count)
        
        for _ in 1...countCellsToDelete {
            let cell = tablesQuery.cells.element(boundBy: 0)
            expectation(for: doesExists, evaluatedWith: cell, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
            cell.swipeLeft()
            let deleteButton = cell.buttons["Delete"]
            expectation(for: doesExists, evaluatedWith: deleteButton, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
            deleteButton.tap()
        }
    }
    
    
    func testRescheduleFromArchive() {
        
        let tabBarsQuery = app.tabBars
        let tablesQuery = app.tables
        let timeTab = tabBarsQuery.buttons["Time"]
        let locationTab = tabBarsQuery.buttons["Location"]
        
        locationTab.tap()
        let locationCellCount = tablesQuery.element(boundBy: 0).cells.count
        
        timeTab.tap()
        let timeCellCount = tablesQuery.element(boundBy: 0).cells.count
        
        rescheduleFromArchive(count: 2)
        
        locationTab.tap()
        let newLocationCellCount = tablesQuery.element(boundBy: 0).cells.count
        XCTAssertEqual(newLocationCellCount, locationCellCount + UInt(2))
        
        timeTab.tap()
        let newTimeCellCount = tablesQuery.element(boundBy: 0).cells.count
        XCTAssertEqual(newTimeCellCount, timeCellCount + UInt(2))
        
    }
    
    func rescheduleFromArchive(count: Int) {
        guard count > 0 else { return }
        let tabBarsQuery = app.tabBars
        let tablesQuery = app.tables
        let archivedTab = tabBarsQuery.buttons["Archived"]

        archivedTab.tap()
        let cellsCount = tablesQuery.element(boundBy: 0).cells.count
        guard cellsCount > 0 else {
            XCTFail("Table has not cell")
            return
        }
        
        for _ in 1...count {
            let cell = tablesQuery.cells.element(boundBy: 0)
            expectation(for: doesExists, evaluatedWith: cell, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
            cell.swipeRight()
            let rescheduleButton = cell.buttons[TableCellButton.reschedule]
            expectation(for: doesExists, evaluatedWith: rescheduleButton, handler: nil)
            waitForExpectations(timeout: 1, handler: { (_) -> Void in cell.swipeRight() })
            XCTAssert(rescheduleButton.exists)
            rescheduleButton.tap()
        }
    }

    func testShowLicenses() {
        
        let tabBarsQuery = app.tabBars
        let archivedTab = tabBarsQuery.buttons["Archived"]
        archivedTab.tap()
        let archivedTaskNavBar = app.navigationBars["Archived Task"]
        XCTAssertTrue(archivedTaskNavBar.exists)
        
        archivedTaskNavBar.buttons["settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.buttons["Show Licenses"].tap()
        let licenseNavBar = app.navigationBars["Licenses"]
        XCTAssertTrue(licenseNavBar.exists)
        
        licenseNavBar.buttons["Done"].tap()
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.exists)
    }
    
    func testAddNewTaskAskForUpgrade() {
        archiveTasks(count: 4)
        let numTasksToAdd = 20 - getTotalTasksCount()
        
        print("Number of task to Add :  \(numTasksToAdd)")
        
        if numTasksToAdd > 0 {
            rescheduleFromArchive(count: numTasksToAdd)
        }
        
        app.tabBars.buttons[TabBarTitle.Time].tap()
        app.navigationBars[NavBar.Title.byDueDate].buttons[NavBar.Button.Add].tap()
        
        let upgradeAlert = app.alerts[Alert.Title.pleaseUpgrade]
        XCTAssertTrue(upgradeAlert.exists)
        upgradeAlert.buttons[Alert.Button.Upgrade].tap()
        
        let upgradeVCNavBar = app.navigationBars[NavBar.Title.upgrade]
        XCTAssertTrue(upgradeVCNavBar.exists)
        upgradeVCNavBar.buttons[NavBar.Button.Done].tap()
        
        guard numTasksToAdd > 0 else { return }
        deleteActiveTasks(count: numTasksToAdd)
    }
}
