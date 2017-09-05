//
//  ChangeToken+CoreDataProperties.swift
//  Todododo
//
//  Created by Wismin Effendi on 9/5/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation
import CoreData


extension ChangeToken {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChangeToken> {
        return NSFetchRequest<ChangeToken>(entityName: "ChangeToken")
    }

    @NSManaged public var previousServerChangeToken: NSObject?

}
