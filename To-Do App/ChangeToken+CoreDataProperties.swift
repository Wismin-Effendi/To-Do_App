//
//  ChangeToken+CoreDataProperties.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension ChangeToken {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChangeToken> {
        return NSFetchRequest<ChangeToken>(entityName: "ChangeToken")
    }

    @NSManaged public var previousServerChangeToken: NSObject?

}
