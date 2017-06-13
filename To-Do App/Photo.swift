//
//  Photo.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

class Photo {
    
    enum Category: Int {
        case shopping
        case exercise
        case studying
        case budgeting
        case spiritual
        case childCare
        case travel
        case social
        case entertainment
        case newCategory
        
        static var allCategories: [Category] {
            var categories = [Category]()
            for i in 0...Category.newCategory.rawValue {
                if let category = Category(rawValue: i) {
                    categories.append(category)
                }
            }
            return categories
        }
        
        func description() -> String {
            switch self {
            case .shopping:
                return "Shopping"
            case .exercise:
                return "Exercise"
            case .studying:
                return "Studying"
            case .budgeting:
                return "Budgeting"
            case .spiritual:
                return "Spiritual"
            case .childCare:
                return "Child care"
            case .travel:
                return "Travel"
            case .social:
                return "Social"
            case .entertainment:
                return "Entertainment"
            case .newCategory:
                return "New Category"
            }
        }
    }
    
    var title: String
    var category: Category
    var imageName: String
    
    init(title: String, category: Category, imageName: String) {
        self.title = title
        self.category = category
        self.imageName = imageName
    }
    
}
