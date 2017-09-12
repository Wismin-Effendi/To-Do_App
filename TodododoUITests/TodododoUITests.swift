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
    }
}

struct DetailView {
    static let tableButtonEdit = "Edit"
}

class TodododoUITests: XCTestCase {
    
    let app = XCUIApplication()

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
        
        let tablesQuery = app.tables
        let cellsCount = tablesQuery.cells.count
        print("Number of cells: \(cellsCount)")
        let kayakingCell = tablesQuery.cells.staticTexts["Kayaking"]
        kayakingCell.tap()
        app.navigationBars["Kayaking"].buttons["Cancel"].tap()
        
        for idx in 0..<cellsCount {
            let cell = tablesQuery.cells.element(boundBy: idx)
            cell.tap()
            let cancelButton = app.navigationBars.buttons["Cancel"]
            cancelButton.tap()
        }
    }
    
    func testAddSomeTasksWithoutLocation() {
        
    }
    
    func testAddSomeTasksWithLocation() {
        let tabBarsQuery = app.tabBars
        let locationButton = tabBarsQuery.buttons["Location"]
        locationButton.tap()
        app.navigationBars.buttons["Add"].tap()
        app.tables.buttons["Edit"].tap()
        let chooseLocationNavigationBar = app.navigationBars["Choose Location"]
        XCTAssertTrue(chooseLocationNavigationBar.exists)
        chooseLocationNavigationBar.buttons["Add"].tap()
        
        let enterBusinessOrLandmarkOrAddressTextField = app.textFields["Enter Business or Landmark or Address"]
        enterBusinessOrLandmarkOrAddressTextField.tap()
        enterBusinessOrLandmarkOrAddressTextField.typeText("99")
        app.typeText(" \r")
        app.alerts["10 locations found"].buttons["Dismiss"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).tap()
        app.otherElements["99 Chicken, 2781 El Camino Real, Santa Clara, CA  95051, United States"].tap()
        
        let moreInfoButton = app.buttons["More Info"]
        moreInfoButton.tap()
        moreInfoButton.tap()
        
        let okButton = app.alerts["Choose Location"].buttons["OK"]
        okButton.tap()
        okButton.tap()
        app.navigationBars["Add New Location"].buttons["Done"].tap()
        chooseLocationNavigationBar.buttons["Jogging"].tap()
        
    }
    
    func testAddNewLocation() {
        
        
        let tablesQuery = app.tables
        let editButton = tablesQuery.buttons["Edit"]
        editButton.tap()
        tablesQuery.staticTexts["99 Ranch Market"].tap()
        editButton.tap()
        editButton.tap()
        app.navigationBars["Choose Location"].buttons["Add"].tap()
        
        let enterBusinessOrLandmarkOrAddressTextField = app.textFields["Enter Business or Landmark or Address"]
        enterBusinessOrLandmarkOrAddressTextField.tap()
        enterBusinessOrLandmarkOrAddressTextField.typeText("99 ")
        app.typeText("\r")
        
        
    }

    func testAddLocationAskForUpgrade() {
        
        app.navigationBars["Task by due date"].buttons["Add"].tap()
        app.alerts["Please Upgrade"].buttons["Upgrade"].tap()
        app.buttons["Restore Purchases"].tap()
        app.navigationBars["Upgrade"].buttons["Done"].tap()
    }
    
    func testEditTaskLocation() {
        
        let tablesQuery = app.tables

        tablesQuery.staticTexts["Due: Sep 7, 2017, 10:09 PM"].tap()
        
        let editButton = tablesQuery.buttons["Edit"]
        editButton.tap()
        tablesQuery.cells.containing(.staticText, identifier:"Costco Gasoline").staticTexts["10401 Research Blvd, Austin, TX  78759, United States"].tap()
        editButton.tap()
        app.navigationBars["Choose Location"].buttons["Add"].tap()
        
        
    }
    
    
    func testDeleteArchivedTasks() {
        
        app.tabBars.buttons["Archived"].tap()
        let tablesQuery = app.tables
        var cellsCount = tablesQuery.cells.count
        guard cellsCount > 0 else {
            XCTFail("Table has not cell")
            return
        }
        for _ in 0..<cellsCount {
            let cell = tablesQuery.cells.element(boundBy: 0)
            cell.swipeLeft()
            cell.buttons["Delete"].tap()
        }
        cellsCount = tablesQuery.cells.count
        XCTAssertTrue(cellsCount == 0)
    }
    
    func testArchiveTask() {
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Test drive a Tesla Model 3"].swipeRight()
        tablesQuery.buttons["checked"].tap()
        tablesQuery.staticTexts["Ginger, instant noodles, etc"].swipeRight()
        tablesQuery.buttons["archive custom"].tap()
        
    }
    
    func testDeleteNonArchivedTask() {
        
        app.tabBars.buttons["Location"].tap()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Gasoline, blueberry, water, and bread"].press(forDuration: 5.7);
        print("stop here")
        
        tablesQuery.buttons["Delete Walk the dog, Due: Sep 7, 2017, 3:19 PM"].tap()
        
        let deleteButton = tablesQuery.buttons["Delete"]
        deleteButton.tap()
        tablesQuery.staticTexts["Jogging "].tap()
        tablesQuery.buttons["Delete Jogging, Due: Sep 7, 2017, 10:09 PM"].tap()
        deleteButton.tap()
        app.navigationBars["Task by due date"].buttons["Done"].tap()
        
    }
    
    func testAddNewLocation2() {
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Gasoline, blueberry, water, and bread"].tap()
        tablesQuery.buttons["Edit"].tap()
        app.navigationBars["Choose Location"].buttons["Add"].tap()
        
        let enterBusinessOrLandmarkOrAddressTextField = app.textFields["Enter Business or Landmark or Address"]
        enterBusinessOrLandmarkOrAddressTextField.tap()
        enterBusinessOrLandmarkOrAddressTextField.typeText("99 ")
        app.typeText("\r")
        app.alerts["10 locations found"].buttons["Dismiss"].tap()
        app.otherElements["99 Ranch Market, 1350 Grant Rd, Mountain View, CA  94040, United States"].tap()
        
        let moreInfoButton = app.buttons["More Info"]
        moreInfoButton.tap()
        moreInfoButton.tap()
        
        let chooseLocationAlert = app.alerts["Choose Location"]
        let textField = chooseLocationAlert.collectionViews.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .textField).element
        textField.typeText(" - 1")
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).tap()
        
        let popoverdismissregionElement = app.otherElements["PopoverDismissRegion"]
        popoverdismissregionElement.tap()
        moreInfoButton.tap()
        moreInfoButton.tap()
        textField.typeText(" - 1")
        
        let okButton = chooseLocationAlert.buttons["OK"]
        okButton.press(forDuration: 2.7);
        popoverdismissregionElement.tap()
        moreInfoButton.tap()
        okButton.tap()
        popoverdismissregionElement.tap()
        moreInfoButton.tap()
        moreInfoButton.tap()
        okButton.tap()
        popoverdismissregionElement.tap()
        moreInfoButton.tap()
        moreInfoButton.tap()
        okButton.tap()
        popoverdismissregionElement.tap()
        moreInfoButton.tap()
        
    }
    
    func testAddNewTask() {
        app.navigationBars["Task by due date"].buttons["Add"].tap()
        app.alerts["Please Upgrade"].buttons["Upgrade"].tap()
        app.navigationBars["Upgrade"].buttons["Done"].tap()
        
    }
    
    func testRescheduleFromArchive() {
        
        let tabBarsQuery = app.tabBars
        let timeTab = tabBarsQuery.buttons["Time"]
        let archivedTab = tabBarsQuery.buttons["Archived"]
        let locationTab = tabBarsQuery.buttons["Location"]
        
        locationTab.tap()
        var tablesQuery = app.tables
        let locationCellCount = tablesQuery.cells.count
        
        timeTab.tap()
        tablesQuery = app.tables
        let timeCellCount = tablesQuery.cells.count
        
        archivedTab.tap()
        tablesQuery = app.tables
        let cellsCount = tablesQuery.cells.count
        guard cellsCount > 0 else {
            XCTFail("Table has not cell")
            return
        }
        let randomIndex = UInt(arc4random_uniform(UInt32(cellsCount)))
        let cell = tablesQuery.cells.element(boundBy: randomIndex)
        cell.swipeRight()
        cell.buttons["clock custom"].tap()
        
        locationTab.tap()
        tablesQuery = app.tables
        let newLocationCellCount = tablesQuery.cells.count
        XCTAssertEqual(newLocationCellCount, locationCellCount + UInt(1))
        
        timeTab.tap()
        tablesQuery = app.tables
        let newTimeCellCount = tablesQuery.cells.count
        XCTAssertEqual(newTimeCellCount, timeCellCount + UInt(1))
        
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
        app.navigationBars["Task by due date"].buttons["Add"].tap()
        
        app.alerts["Please Upgrade"].buttons["Upgrade"].tap()
        
        app.navigationBars["Upgrade"].buttons["Done"].tap()
    }
    
    func testAddTaskWithoutLocation() {
        
    }
    
    func testAddTaskWithLocation() {
        
    }
    
    func testCompleteSomeTask() {
        
    }
    
    func testAddNewLocation3() {
        
        let app = XCUIApplication()
        app.navigationBars["Task by due date"].buttons["Add"].tap()
        app.tables.buttons["Edit"].tap()
        app.navigationBars["Choose Location"].buttons["Add"].tap()
        
        let enterBusinessOrLandmarkOrAddressTextField = app.textFields["Enter Business or Landmark or Address"]
        enterBusinessOrLandmarkOrAddressTextField.tap()
        enterBusinessOrLandmarkOrAddressTextField.typeText("99 ")
        app.typeText("\r")
        app.alerts["10 locations found"].buttons["Dismiss"].tap()
        app.otherElements["Low T 99, 5150 Graves Ave, Unit 11H, San Jose, CA  95129, United States"].tap()
        
        let moreInfoButton = app.buttons["More Info"]
        moreInfoButton.tap()
        
        let chooseLocationAlert = app.alerts["Choose Location"]
        let okButton = chooseLocationAlert.buttons["OK"]
        okButton.tap()
        
        let popoverdismissregionElement = app.otherElements["PopoverDismissRegion"]
        popoverdismissregionElement.tap()
        popoverdismissregionElement.tap()
        moreInfoButton.tap()
        okButton.tap()
        moreInfoButton.tap()
        
        let cancelButton = chooseLocationAlert.buttons["Cancel"]
        cancelButton.tap()
        cancelButton.tap()
        moreInfoButton.tap()
        cancelButton.tap()
        cancelButton.tap()
        
    }
}
