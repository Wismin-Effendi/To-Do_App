//
//  LocationAnnotation+CoreDataClass.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

@objc(LocationAnnotation)
public class LocationAnnotation: NSManagedObject {

    public func setDefaultsForLocalCreate() {
        self.localUpdate = NSDate()
        self.needsUpload = true
        self.pendingDeletion = false
    }
}
