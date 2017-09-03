//
//  StringBuilder.swift
//  StringBuilder
//
//  Created by Matthew Wyskiel on 9/30/14.
//  Copyright (c) 2014 Matthew Wyskiel. All rights reserved.
//

import Foundation

open class StringBuilder {
    
    fileprivate(set) var string: String
    
    public init() {
        string = ""
    }
    
    public init(string: String) {
        self.string = string
    }
    
    open func append<T>(_ itemToAppend: T) -> Self {
        self.string += "\(itemToAppend)"
        return self
    }
    
    open func insertItem<T>(_ item: T, atIndex index: Int) -> Self {
        let mutableString = NSMutableString(string: self.string)
        mutableString.insert("\(item)", at: index)
        self.string = mutableString as String
        return self
    }
    
    open func toString() -> String {
        return string;
    }
   
}
