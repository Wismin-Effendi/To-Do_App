//
//  Constants.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/15/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation


public struct ModelName {
    public static let ToDo = "ToDoApp"
}

public struct CellIdentifier {
    public static let TaskCell = "TaskCell"
    public static let LocationName = "LocationName"
}

public struct TaskCategory {
    static let others = "others"
    static let home = "home"
    static let errants = "errants"
    static let shopping = "shopping"
    static let social = "social"
    static let spiritual = "spiritual"
    static let childCare = "child care"
    static let exercise = "exercise"
    static let study = "study"
    static let entertainment = "entertainment"
}

public struct Constant {
    public static let toDoCategoryPerRow: CGFloat = 3
    public static let hardCodedPadding: CGFloat = 30.0
}

public struct SegueIdentifier {
    public static let AddNewLocation = "AddNewLocation"
    public static let LocationList = "LocationList"
}

extension UserDefaults {
    public struct Keys {
        public static let mixpanelIdentity = "mixpanelIdentity"
    }
}



