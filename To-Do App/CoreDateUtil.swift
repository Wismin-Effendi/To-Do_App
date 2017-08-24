//
//  CoreDateUtil.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/23/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import ToDoCoreDataCloudKit

class CoreDataUtil {
    
    static func locationAnnotation(by identifier: String, managedContext: NSManagedObjectContext) -> LocationAnnotation? {
        let fetchRequest: NSFetchRequest<LocationAnnotation> = LocationAnnotation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(LocationAnnotation.identifier), identifier)
        fetchRequest.fetchLimit = 1
        do {
            let results = try managedContext.fetch(fetchRequest)
            return results.first
        } catch {
            fatalError("Failed to fetch location annotation from core Data. \(error.localizedDescription)")
        }
    }
    
}

