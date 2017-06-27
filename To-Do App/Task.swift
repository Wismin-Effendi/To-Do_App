//
//  Task.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

class Task {
    
    // MARK: Properties 
    
    var name: String
    var category: String
    
    // MARK: Initialization
    
    init(name: String, category: String) {
        self.name = name
        self.category = category
    }
}
