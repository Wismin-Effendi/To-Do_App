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


public class Predicates {
    
    public static let NewLocationAnnotation = NSPredicate(format: "%K == nil", #keyPath(LocationAnnotation.ckMetadata))
    public static let UpdatedLocationAnnotation = NSPredicate(format: "%K == YES AND %K != nil",
                                                 #keyPath(LocationAnnotation.needsUpload),
                                                 #keyPath(LocationAnnotation.ckMetadata))
    public static let DeletedLocationAnnotation = NSPredicate(format: "%K == YES", #keyPath(LocationAnnotation.pendingDeletion))
    
    public static let NewTask = NSPredicate(format: "%K == nil", #keyPath(Task.ckMetadata))
    public static let UpdatedTask = NSPredicate(format: "%K == YES AND %K != nil",
                                                #keyPath(Task.needsUpload),
                                                #keyPath(Task.ckMetadata))
    public static let DeletedTask = NSPredicate(format: "%K == YES", #keyPath(Task.pendingDeletion))
 
    public static let LocationAnnotationNotPendingDeletion = NSPredicate(format: "%K == NO", #keyPath(LocationAnnotation.pendingDeletion))
    
    public static let TaskNotPendingDeletion = NSPredicate(format: "%K == NO", #keyPath(Task.pendingDeletion))

}
