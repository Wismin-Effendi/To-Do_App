//
//  Predicates.swift
//  LocationAnnotation and Task
//
//  Created by Wismin Effendi on 8/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


class Predicates {
    
    static let NewLocationAnnotation = NSPredicate(format: "%K == nil", #keyPath(LocationAnnotation.ckMetadata))
    static let UpdatedLocationAnnotation = NSPredicate(format: "%K == YES AND %K != nil",
                                                 #keyPath(LocationAnnotation.needsUpload),
                                                 #keyPath(LocationAnnotation.ckMetadata))
    static let DeletedLocationAnnotation = NSPredicate(format: "%K == YES", #keyPath(LocationAnnotation.pendingDeletion))
    
    static let NewTask = NSPredicate(format: "%K == nil", #keyPath(Task.ckMetadata))
    static let UpdatedTask = NSPredicate(format: "%K == YES AND %K != nil",
                                                #keyPath(Task.needsUpload),
                                                #keyPath(Task.ckMetadata))
    static let DeletedTask = NSPredicate(format: "%K == YES", #keyPath(Task.pendingDeletion))
 
    static let LocationAnnotationNotPendingDeletion = NSPredicate(format: "%K == NO", #keyPath(LocationAnnotation.pendingDeletion))
}
