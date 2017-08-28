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
    
    public func setDefaultsForLocalCreate() {
        self.localUpdate = NSDate()
        self.completed = false
        self.completionDate = NSDate.init(timeIntervalSinceReferenceDate: 0)
        self.needsUpload = true
        self.pendingDeletion = false
        self.identifier = UUID().uuidString
        self.archived = false
        self.dueDate = (Date() + 3.hours) as NSDate
        self.reminder = false
        self.reminderDate = dueDate
        self.name = "Rename this new Task"
    }
    
    
    private func isDateIn(_ referenceDate: Date, component: Calendar.Component, input date: Date) -> Bool {
        return date.isIn(date: referenceDate, granularity: component)
    }
    
    var dueDateType: String {
        let now = Date()
        let dueDate = self.dueDate as Date
        
        if isDateIn(now, component: .day, input: dueDate) {
            return TimeOrder.today.rawValue
        } else if dueDate > now {
            return futureDateType(dueDate)
        } else {
            return pastDateType(dueDate)
        }
    }
    
    var completionDateType: String {
        let now = Date()
        let completionDate = self.completionDate! as Date
        
        if isDateIn(now, component: .day, input: completionDate) {
            return TimeOrder.today.rawValue
        } else if completionDate > now {
            return futureDateType(completionDate)
        } else {
            return pastDateType(completionDate)
        }
    }
    
    private func futureDateType(_ inputDate: Date) -> String {
        let now = Date()
        let tomorrow = now + 1.day
        let twoDaysFromNow = tomorrow + 1.day
        let nextWeek = now + 1.week
        let twoWeeksFromNow = nextWeek + 1.week
        
        if isDateIn(tomorrow, component: .day, input: inputDate) {
            return TimeOrder.tomorrow.rawValue
        } else if isDateIn(twoDaysFromNow, component: .day, input: inputDate) {
            return TimeOrder.twoDaysFromNow.rawValue
        } else if isDateIn(now, component: .weekOfYear, input: inputDate) {
            return TimeOrder.futureDaysInThisWeek.rawValue
        } else if isDateIn(nextWeek, component: .weekOfYear, input: inputDate) {
            return TimeOrder.nextWeek.rawValue
        } else if isDateIn(twoWeeksFromNow, component: .weekOfYear, input: inputDate) {
            return TimeOrder.twoWeeksFromNow.rawValue
        } else {
            return TimeOrder.sometimeInTheFuture.rawValue
        }
    }
    
    private func pastDateType(_ inputDate: Date) -> String {
        let now = Date()
        let yesterday = now - 1.day
        let twoDaysAgo = yesterday - 1.day
        let lastWeek = now - 1.week
        let twoWeeksAgo = lastWeek - 1.week
        
        if isDateIn(yesterday, component: .day, input: inputDate) {
            return TimeOrder.yesterday.rawValue
        } else if isDateIn(twoDaysAgo, component: .day, input: inputDate) {
            return TimeOrder.twoDaysAgo.rawValue
        } else if isDateIn(now, component: .weekOfYear, input: inputDate) {
            return TimeOrder.previousDaysInThisWeek.rawValue
        } else if isDateIn(lastWeek, component: .weekOfYear, input: inputDate) {
            return TimeOrder.lastWeek.rawValue
        } else if isDateIn(twoWeeksAgo, component: .weekOfYear, input: inputDate) {
            return TimeOrder.twoWeeksAgo.rawValue
        } else {
            return TimeOrder.sometimeInThePast.rawValue
        }
    }
    
}
