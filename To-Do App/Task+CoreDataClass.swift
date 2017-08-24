//
//  Task+CoreDataClass.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/18/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import SwiftDate

@objc(Task)
public class Task: NSManagedObject {
    func setDefaultsForNewTask() {
        self.completed = false
    }
    
    var descriptions: String {
        return "\(name!) Priority: \(priority)  Ranking: \(ranking)"
    }
    
    
    private func isDueDateIsIn(_ referenceDate: Date, component: Calendar.Component) -> Bool {
        let dueDate = self.dueDate! as Date
        return dueDate.isIn(date: referenceDate, granularity: component)
    }
    
    var dueDateType: String {
        let now = Date()
        let dueDate = self.dueDate! as Date
        
        if isDueDateIsIn(now, component: .day) {
            return TimeOrder.today.rawValue
        } else if dueDate > now {
            return futureDateType(dueDate)
        } else {
            return pastDateType(dueDate)
        }
    }
    
    private func futureDateType(_ dueDate: Date) -> String {
        let now = Date()
        let tomorrow = now + 1.day
        let twoDaysFromNow = tomorrow + 1.day
        let nextWeek = now + 1.week
        let twoWeeksFromNow = nextWeek + 1.week
        
        if isDueDateIsIn(tomorrow, component: .day) {
            return TimeOrder.tomorrow.rawValue
        } else if isDueDateIsIn(twoDaysFromNow, component: .day) {
            return TimeOrder.twoDaysFromNow.rawValue
        } else if isDueDateIsIn(now, component: .weekOfYear) {
            return TimeOrder.futureDaysInThisWeek.rawValue
        } else if isDueDateIsIn(nextWeek, component: .weekOfYear) {
            return TimeOrder.nextWeek.rawValue
        } else if isDueDateIsIn(twoWeeksFromNow, component: .weekOfYear) {
            return TimeOrder.twoWeeksFromNow.rawValue
        } else {
            return TimeOrder.sometimeInTheFuture.rawValue
        }
    }
    
    private func pastDateType(_ dueDate: Date) -> String {
        let now = Date()
        let yesterday = now - 1.day
        let twoDaysAgo = yesterday - 1.day
        let lastWeek = now - 1.week
        let twoWeeksAgo = lastWeek - 1.week
        
        if isDueDateIsIn(yesterday, component: .day) {
            return TimeOrder.yesterday.rawValue
        } else if isDueDateIsIn(twoDaysAgo, component: .day) {
            return TimeOrder.twoDaysAgo.rawValue
        } else if isDueDateIsIn(now, component: .weekOfYear) {
            return TimeOrder.previousDaysInThisWeek.rawValue
        } else if isDueDateIsIn(lastWeek, component: .weekOfYear) {
            return TimeOrder.lastWeek.rawValue
        } else if isDueDateIsIn(twoWeeksAgo, component: .weekOfYear) {
            return TimeOrder.twoWeeksAgo.rawValue
        } else {
            return TimeOrder.sometimeInThePast.rawValue
        }
    }
    
}
