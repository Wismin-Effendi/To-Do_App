//
//  AppDelegateHelper.swift
//  Todododo
//
//  Created by Wismin Effendi on 9/15/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation
import ToDoCoreDataCloudKit
import CoreData

struct AppDelegateHelper {
    static func setupConfigurationUserDefaults() {
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: UserDefaults.Keys.dueHoursFromNow) == nil {
            userDefaults.set(3.0, forKey: UserDefaults.Keys.dueHoursFromNow)
        }
        
        if userDefaults.object(forKey: UserDefaults.Keys.archivePastCompletion) == nil {
            userDefaults.set(true, forKey: UserDefaults.Keys.archivePastCompletion)
        }
        
        if userDefaults.object(forKey: UserDefaults.Keys.deleteUnusedArchivedLocations) == nil {
            userDefaults.set(true, forKey: UserDefaults.Keys.deleteUnusedArchivedLocations)
        }
    }
    
    static func performAchivingAndDeletion(container: NSPersistentContainer) {
        
        let userDefaults = UserDefaults.standard
        let deleteUnusedLocationAnnotations = userDefaults.bool(forKey: UserDefaults.Keys.deleteUnusedArchivedLocations)
        let archivePastCompletedTask = userDefaults.bool(forKey: UserDefaults.Keys.archivePastCompletion)
        
        if deleteUnusedLocationAnnotations {
            CoreDataUtil.deleteUnusedArchivedLocations(moc: container.newBackgroundContext())
        }
        
        // We need this in main context so NSFetchRequestController could detect and update the table
        if archivePastCompletedTask {
            DispatchQueue.main.async {
                CoreDataUtil.autoArchivingPastCompletedTasks(moc: container.viewContext)
            }
        }
    }
}
