//
//  DateUtil.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/24/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import SwiftDate


public struct DateUtil {
    
    public static func shortDateText(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
    
    public static func getDueDateAfterMove(dueDateRowBefore: Date?, dueDateRowAfter: Date?) -> Date {
        // 1. if move to the top: after - 15 mins
        // 2. if move to the last: before + 15 mins 
        // 3. if in between: after - delta/2
        guard dueDateRowBefore != nil || dueDateRowAfter != nil else { return Date() }
        switch (dueDateRowBefore, dueDateRowAfter) {
            case (nil, let dueAfter):
                return dueAfter! - 15.minutes
            case (let dueBefore, nil):
                return dueBefore! + 15.minutes
            default:
                let delta = dueDateRowAfter! - dueDateRowBefore!
                return dueDateRowAfter!.addingTimeInterval(delta/2)
        }
    }
    
    public static func isInThePastDays(date: Date) -> Bool {
        let now = Date()
        let startOfDay = now.startOfDay
        return date < startOfDay
    }
}
